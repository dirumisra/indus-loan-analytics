-- =============================================
-- File     : 01_create_silver_table.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 5 - Silver Layer
-- Purpose  : Create silver.applications table
--            Contains cleaned typed columns
--            Plus 14 derived business columns
--            Joins masked values from bronze
--            Source for all Gold layer tables
-- =============================================

USE IndusLoanDB;
GO

-- =============================================

CREATE TABLE silver.applications (

    -- Links back to bronze batch_id
    -- Which bronze load created this silver row
    silver_id   INT IDENTITY(1,1) NOT NULL,
    
    -- Which bronze batch this row came from
    batch_id    INT               NOT NULL,
    
    -- When this row was loaded into silver
    load_timestamp      DATETIME    NOT NULL    DEFAULT GETDATE(),

    -- ==========================================
    -- SECTION 2 : Identifier Columns
    -- Original columns from bronze
    -- Now cast to correct data types
    -- VARCHAR in raw and bronze
    -- Proper types here in silver
    -- ==========================================

    -- Primary identifier — now proper INT
    -- Was VARCHAR(20) in raw and bronze

    App_Id  INT NOT NULL,

    -- Application serial number
    Appl_Running_Serial_No  VARCHAR(30) NULL,

    -- Scheme identifier
    Schema_Id   VARCHAR(50) NULL,

    -- ==========================================
    -- SECTION 3 : Product and Campaign Columns
    -- Original columns kept as VARCHAR
    -- Values are clean enough from source
    -- No transformation needed here
    -- ==========================================

    -- Loan product code
    -- Example: LAA701, LAA702, PLCIBIL

    Product     VARCHAR(20)     NULL,

    -- Campaign that sourced this application
    -- 165 unique values in our data
    Campaign_Type       VARCHAR(100)    NULL,

    -- Fee code associated with product
    Fee_Code                VARCHAR(20)     NULL,

    -- ==========================================
    -- SECTION 4 : Decision Columns
    -- Original decision values kept as VARCHAR
    -- Clean date columns added as proper DATE type
    -- Original messy date strings also kept
    -- for audit and traceability purposes
    -- ==========================================

    -- Original Decision value from source
    -- Example: FINISH, DECLINED, CBLR, REJ
    Decision                VARCHAR(20)     NULL,

    -- Original messy date string kept for audit
    -- Example: '02-08-16 19:27'
    Signed_Date             VARCHAR(30)     NULL,

    -- Clean proper DATE converted from string
    -- Example: '02-08-16' → 2016-08-02
    -- NULL if date conversion fails
    signed_date_clean       DATE            NULL,

    -- Original messy decision date kept for audit
    Decision_Date           VARCHAR(30)     NULL,

    -- Clean proper DATE converted from string
    decision_date_clean     DATE            NULL,

    -- Original Stage value from source
    -- Example: Approved, Quick Data Entry...
    Stage                   VARCHAR(100)    NULL,

    -- Decline codes as comma separated string
    -- Example: DVX183,DPX046
    -- Will be exploded in Phase 6
    Decline_Code            VARCHAR(200)    NULL,

    -- ==========================================
    -- SECTION 5 : Channel and Agent Columns
    -- Original sourcing information
    -- Real agent codes kept here for reference
    -- Masked codes come from masked_attributes
    -- ==========================================

    -- How application was sourced
    -- Example: INH, DSA, BRANCH, PBA
    Sourcing_Channel        VARCHAR(50)     NULL,

    -- DSA company code
    -- Example: C27500
    DSA_Code                VARCHAR(20)     NULL,

    -- Real DSE agent code kept for audit
    -- Masked version comes from masked_attributes
    DSE_Code                VARCHAR(20)     NULL,

    -- Real secondary DSE code kept for audit
    Secondary_DSE_Code      VARCHAR(20)     NULL,

    -- Branch where application was sourced
    Sourcing_Branch_Code    VARCHAR(20)     NULL,

    -- ==========================================
    -- SECTION 6 : Location and Financial Columns
    -- Loan amount cast to proper INT
    -- Original VARCHAR kept for audit
    -- City columns cleaned and standardized
    -- ==========================================

    -- Original loan amount string kept for audit
    -- Example: '415000'
    Loan_Amount             VARCHAR(20)     NULL,

    -- Loan amount as proper INT for calculations
    -- Example: '415000' → 415000
    -- NULL if conversion fails
    loan_amount_clean       INT             NULL,

    -- Residence city original value
    Residence_City          VARCHAR(100)    NULL,

    -- Cleaned uppercase trimmed city name
    -- Example: ' mumbai ' → MUMBAI
    residence_city_clean    VARCHAR(100)    NULL,

    -- Mailing city original value
    Mailing_City            VARCHAR(100)    NULL,

    -- ==========================================
    -- SECTION 7 : Customer Profile Columns
    -- Original values kept as VARCHAR
    -- Used for segmentation in Gold layer
    -- ==========================================

    -- Employment type
    -- Example: SALARIED, SELF EMPLOYED
    Type_Of_Organization    VARCHAR(100)    NULL,

    -- Customer category
    -- Example: SC10, SC20, SC30
    You_Are                 VARCHAR(200)    NULL,

    -- ==========================================
    -- SECTION 8 : Masked PII Columns
    -- These columns come from
    -- bronze.masked_attributes table
    -- Joined during silver load procedure
    -- Real PAN and Name never appear here
    -- Silver and Gold only see masked values
    -- ==========================================

    -- Customer initials only
    -- Example: RAJEEV RAMADHAR SINGH → R.S
    masked_name             VARCHAR(20)     NULL,

    -- SHA2_256 hashed PAN number
    -- Cannot be reversed to get real PAN
    masked_pan              VARCHAR(64)     NULL,

    -- Birth year only — no full date
    -- Example: 07-05-75 → 1975
    birth_year              INT             NULL,

    -- Pseudonym agent code
    -- Example: C27500 → AGT_00001
    masked_dse_code         VARCHAR(20)     NULL,

    -- Pseudonym secondary agent code
    masked_secondary_dse    VARCHAR(20)     NULL,

    -- ==========================================
    -- SECTION 9 : Derived Business Columns
    -- These 14 columns do not exist in source
    -- Built purely from business logic
    -- This is what makes Silver valuable
    -- Power BI and Gold use these columns
    -- ==========================================

    -- Derived Column 1 : final_status
    -- Single unified status for every application
    -- Built from Decision + Stage combination
    -- Example: Decision=FINISH + Stage=Approved
    --          → final_status = Approved
    final_status            VARCHAR(20)     NULL,

    -- Derived Column 2 : is_approved
    -- BIT flag for approved applications
    -- 1 = approved, 0 = not approved
    -- Makes approval rate calculation simple
    -- COUNT(is_approved) / COUNT(*) = rate
    is_approved             BIT             NULL,

    -- Derived Column 3 : is_declined
    -- BIT flag for declined applications
    is_declined             BIT             NULL,

    -- Derived Column 4 : is_in_process
    -- BIT flag for applications still in process
    is_in_process           BIT             NULL,

    -- Derived Column 5 : tat_hours
    -- Turnaround time in hours
    -- How long from signing to decision
    -- decision_date_clean - signed_date_clean
    -- NULL if either date is missing
    tat_hours               INT             NULL,

    -- Derived Column 6 : tat_bucket
    -- Groups tat_hours into time bands
    -- <24h = same day processing
    -- 24-48h = next day
    -- 48-72h = two days
    -- 72h+ = delayed processing
    tat_bucket              VARCHAR(20)     NULL,

    -- Derived Column 7 : loan_amount_band
    -- Groups loan amounts into bands
    -- <2L   = below 200000
    -- 2-5L  = 200000 to 500000
    -- 5-10L = 500000 to 1000000
    -- 10L+  = above 1000000
    loan_amount_band        VARCHAR(20)     NULL,

    -- Derived Column 8 : age_band
    -- Groups customers into age ranges
    -- Built from birth_year
    -- 2026 - birth_year = approximate age
    -- <25 / 25-35 / 35-45 / 45-55 / 55+
    age_band                VARCHAR(20)     NULL,

    -- Derived Column 9 : residence_city_clean
    -- Already declared in Section 6
    -- Uppercase trimmed city name

    -- Derived Column 10 : city_tier
    -- Classifies city into tier
    -- Tier 1 = Mumbai, Delhi, Bangalore...
    -- Tier 2 = Pune, Ahmedabad, Jaipur...
    -- Tier 3 = all other cities
    city_tier               VARCHAR(10)     NULL,

    -- Derived Column 11 : sourcing_channel_group
    -- Groups channels into categories
    -- DIRECT = INH
    -- PARTNER = DSA
    -- BRANCH = BRANCH, PBA
    sourcing_channel_group  VARCHAR(20)     NULL,

    -- Derived Column 12 : is_high_value
    -- BIT flag for high value loans
    -- 1 = loan_amount_clean > 1000000
    -- 0 = below 1000000
    is_high_value           BIT             NULL,

    -- Derived Column 13 : processing_year
    -- Year of decision date
    -- Used for year wise trend analysis
    processing_year         INT             NULL,

    -- Derived Column 14 : processing_month
    -- Month of decision date
    -- Used for month wise trend analysis
    processing_month        INT             NULL,

    -- Primary key on silver_id
    CONSTRAINT PK_silver_applications
        PRIMARY KEY (silver_id)
);
GO

PRINT 'TABLE silver.applications created successfully';
GO