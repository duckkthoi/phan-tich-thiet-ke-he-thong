-- =====================================================================
-- GaraMan module 2 - CSDL riêng garaman_module2 (14 bảng, giống Bảng 3.4)
-- Theo mục 3.2 / Bảng 3.4 báo cáo BaoCao_GaraMan_B23DCCN185.docx
-- Hệ quản trị: MySQL 8
-- =====================================================================
CREATE DATABASE IF NOT EXISTS garaman_module2
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE garaman_module2;

CREATE TABLE tblMember (
    id        BIGINT       NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    username  VARCHAR(50)  NOT NULL,
    password  VARCHAR(255) NOT NULL,
    phone     VARCHAR(20),
    email     VARCHAR(100),
    PRIMARY KEY (id),
    UNIQUE KEY uq_member_username (username)
);

CREATE TABLE tblStaff (
    member_id BIGINT      NOT NULL,
    position  VARCHAR(50) NOT NULL,
    PRIMARY KEY (member_id),
    CONSTRAINT fk_staff_member FOREIGN KEY (member_id) REFERENCES tblMember (id) ON DELETE RESTRICT
);

CREATE TABLE tblCustomer (
    member_id BIGINT       NOT NULL,
    address   VARCHAR(255),
    PRIMARY KEY (member_id),
    CONSTRAINT fk_customer_member FOREIGN KEY (member_id) REFERENCES tblMember (id) ON DELETE RESTRICT
);

CREATE TABLE tblTechnician (
    id        BIGINT       NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    phone     VARCHAR(20),
    PRIMARY KEY (id)
);

CREATE TABLE tblItem (
    id          BIGINT        NOT NULL AUTO_INCREMENT,
    name        VARCHAR(150)  NOT NULL,
    description TEXT,
    price       DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT ck_item_price CHECK (price >= 0)
);

CREATE TABLE tblService (
    item_id            BIGINT NOT NULL,
    estimated_duration INT    NOT NULL,
    PRIMARY KEY (item_id),
    CONSTRAINT fk_service_item FOREIGN KEY (item_id) REFERENCES tblItem (id) ON DELETE RESTRICT,
    CONSTRAINT ck_service_duration CHECK (estimated_duration > 0)
);

CREATE TABLE tblSparePart (
    item_id           BIGINT NOT NULL,
    quantity_in_stock INT    NOT NULL DEFAULT 0,
    PRIMARY KEY (item_id),
    CONSTRAINT fk_sparepart_item FOREIGN KEY (item_id) REFERENCES tblItem (id) ON DELETE RESTRICT,
    CONSTRAINT ck_sparepart_stock CHECK (quantity_in_stock >= 0)
);

CREATE TABLE tblSupplier (
    id             BIGINT       NOT NULL AUTO_INCREMENT,
    name           VARCHAR(150) NOT NULL,
    address        VARCHAR(255),
    phone          VARCHAR(20),
    contact_person VARCHAR(100),
    PRIMARY KEY (id)
);

CREATE TABLE tblAppointment (
    id               BIGINT      NOT NULL AUTO_INCREMENT,
    customer_id      BIGINT      NOT NULL,
    appointment_time DATETIME    NOT NULL,
    status           VARCHAR(30) NOT NULL,
    note             TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_appointment_customer FOREIGN KEY (customer_id) REFERENCES tblCustomer (member_id) ON DELETE RESTRICT
);

CREATE TABLE tblAppointmentDetail (
    id             BIGINT NOT NULL AUTO_INCREMENT,
    appointment_id BIGINT NOT NULL,
    service_id     BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_appointmentdetail (appointment_id, service_id),
    CONSTRAINT fk_appdetail_appointment FOREIGN KEY (appointment_id) REFERENCES tblAppointment (id) ON DELETE CASCADE,
    CONSTRAINT fk_appdetail_service FOREIGN KEY (service_id) REFERENCES tblService (item_id) ON DELETE RESTRICT
);

CREATE TABLE tblInvoice (
    id             BIGINT      NOT NULL AUTO_INCREMENT,
    customer_id    BIGINT      NOT NULL,
    sales_staff_id BIGINT      NOT NULL,
    appointment_id BIGINT      NULL,
    created_date   DATETIME    NOT NULL,
    status         VARCHAR(30) NOT NULL,
    payment_date   DATETIME    NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_invoice_appointment (appointment_id),
    CONSTRAINT fk_invoice_customer FOREIGN KEY (customer_id) REFERENCES tblCustomer (member_id) ON DELETE RESTRICT,
    CONSTRAINT fk_invoice_staff FOREIGN KEY (sales_staff_id) REFERENCES tblStaff (member_id) ON DELETE RESTRICT,
    CONSTRAINT fk_invoice_appointment FOREIGN KEY (appointment_id) REFERENCES tblAppointment (id) ON DELETE RESTRICT
);

CREATE TABLE tblInvoiceDetail (
    id            BIGINT        NOT NULL AUTO_INCREMENT,
    invoice_id    BIGINT        NOT NULL,
    item_id       BIGINT        NOT NULL,
    technician_id BIGINT        NULL,
    quantity      INT           NOT NULL,
    unit_price    DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_invoicedetail (invoice_id, item_id),
    CONSTRAINT fk_invdetail_invoice FOREIGN KEY (invoice_id) REFERENCES tblInvoice (id) ON DELETE CASCADE,
    CONSTRAINT fk_invdetail_item FOREIGN KEY (item_id) REFERENCES tblItem (id) ON DELETE RESTRICT,
    CONSTRAINT fk_invdetail_technician FOREIGN KEY (technician_id) REFERENCES tblTechnician (id) ON DELETE RESTRICT,
    CONSTRAINT ck_invdetail_quantity CHECK (quantity > 0),
    CONSTRAINT ck_invdetail_price CHECK (unit_price >= 0)
);

CREATE TABLE tblImportReceipt (
    id                 BIGINT      NOT NULL AUTO_INCREMENT,
    supplier_id        BIGINT      NOT NULL,
    warehouse_staff_id BIGINT      NOT NULL,
    import_date        DATETIME    NOT NULL,
    status             VARCHAR(30) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_import_supplier FOREIGN KEY (supplier_id) REFERENCES tblSupplier (id) ON DELETE RESTRICT,
    CONSTRAINT fk_import_staff FOREIGN KEY (warehouse_staff_id) REFERENCES tblStaff (member_id) ON DELETE RESTRICT
);

CREATE TABLE tblImportDetail (
    id                BIGINT        NOT NULL AUTO_INCREMENT,
    import_receipt_id BIGINT        NOT NULL,
    spare_part_id     BIGINT        NOT NULL,
    quantity          INT           NOT NULL,
    import_price      DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_importdetail (import_receipt_id, spare_part_id),
    CONSTRAINT fk_impdetail_receipt FOREIGN KEY (import_receipt_id) REFERENCES tblImportReceipt (id) ON DELETE CASCADE,
    CONSTRAINT fk_impdetail_sparepart FOREIGN KEY (spare_part_id) REFERENCES tblSparePart (item_id) ON DELETE RESTRICT,
    CONSTRAINT ck_impdetail_quantity CHECK (quantity > 0),
    CONSTRAINT ck_impdetail_price CHECK (import_price >= 0)
);
