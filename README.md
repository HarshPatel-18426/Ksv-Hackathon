# 🌉 VendorBridge ERP

VendorBridge is a premium, state-of-the-art **Procurement & Vendor Management ERP** application built with **Flutter** and **Material Design 3**. It is designed to streamline the procurement lifecycle, optimize vendor relationships, automate multi-stage approvals, and handle complex tax (GST) calculations within an intuitive, responsive dashboard.

---

## 🚀 Key Features

### 👥 Role-Based Access Control (RBAC)
Tailored user experiences and security permissions for four core roles:
- **Admin**: Full access, settings management, system defaults, and user administration.
- **Procurement Officer**: Manages RFQs, creates/evaluates vendor registry, runs side-by-side quotation comparisons.
- **Manager**: Authorizes purchase orders and reviews approvals via a visual pipeline.
- **Vendor**: Submits quotations, tracks invoices, and updates verification details.

### 🔄 End-to-End Procurement Workflow
1. **Vendor Registry**: Searchable directory with performance scoring, blacklisting, and document upload support.
2. **RFQ Management**: Visual stepper-based tracking from draft, active bidding, evaluation, through to completion.
3. **Quotation Comparison**: Side-by-side matrix comparing prices, quality scoring, delivery timelines, and automatic highlight of the lowest bidder.
4. **Approval Kanban**: A visual board to approve, reject, or request changes on pending procurement requests.
5. **Purchase Orders & Invoices**: Rich automated invoicing with PDF layout generation and native printing.

### 📊 Indian GST Tax Engine
Automatically differentiates tax calculations based on location:
- **Intra-State**: Applies **CGST (9%)** and **SGST (9%)**.
- **Inter-State**: Applies **IGST (18%)**.
- Outputs clean itemized breakdowns and formatted currency values in INR.

### 📈 Reports & Analytics
- Visualized spend trends and cycle times using `fl_chart`.
- One-click CSV exporter for reports and system audit logs.

### 📱 Responsive & Adaptive UI
Adapts dynamically to different screen dimensions:
- **Mobile**: Intuitive bottom navigation bar with quick-action speed-dial FABs.
- **Tablet / Web / Desktop**: Navigation rail or persistent drawer options for maximized canvas usage.

---

## 🛠 Tech Stack & Dependencies

- **Framework**: Flutter (Dart) with `useMaterial3: true`
- **Routing**: `go_router` for deep linking and declarative route-based redirection
- **State Management**: `provider` for high-performance, clean state architecture
- **Charts & Visuals**: `fl_chart` for dashboard KPI analytics
- **Data Display**: `data_table_2` for advanced sortable and paginated tables
- **PDF & Printing**: `pdf` and `printing` for on-the-fly letterhead and PO downloads
- **Local Storage**: `shared_preferences` for role-switching session persistence
- **Effects**: `shimmer` for smooth loading skeletons

---

## 📂 Project Structure

```
lib/
├── main.dart                 # Application entry point & theme configuration
├── models/                   # Strongly-typed data models & mock engines
│   ├── user_role.dart
│   ├── vendor.dart
│   ├── rfq.dart
│   ├── quotation.dart
│   ├── approval.dart
│   ├── purchase_order.dart
│   ├── invoice.dart
│   └── activity.dart
├── providers/                # Central state providers (Auth & ERP State)
│   ├── auth_provider.dart
│   └── erp_provider.dart
├── router/                   # Declarative routing and role-based guards
│   └── app_router.dart
├── screens/                  # Feature screens and workflows
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── vendor_registry_screen.dart
│   ├── rfq_management_screen.dart
│   ├── quotation_comparison_screen.dart
│   ├── approval_workflow_screen.dart
│   ├── purchase_orders_screen.dart
│   ├── invoice_management_screen.dart
│   ├── reports_analytics_screen.dart
│   ├── activity_log_screen.dart
│   └── settings_screen.dart
├── utils/                    # Common formatting and helper utilities
│   └── formatters.dart
└── widgets/                  # Shared modular components
    ├── app_search_bar.dart
    ├── kpi_card.dart
    ├── status_chip.dart
    ├── gst_breakdown_table.dart
    ├── confirm_dialog.dart
    ├── empty_state.dart
    └── responsive_scaffold.dart
```

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK (v3.0.0 or higher)
- Android Studio / Xcode / VS Code
- Chrome or native Desktop runners for testing

### Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/HarshPatel-18426/Ksv-Hackathon.git
   cd Ksv-Hackathon
   ```

2. Fetch pub dependencies:
   ```bash
   flutter pub get
   ```

3. Run the development server (Web, macOS, iOS, or Android):
   ```bash
   flutter run -d chrome
   ```

4. Run the automated test suites:
   ```bash
   flutter test
   ```
