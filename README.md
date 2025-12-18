# URide - URide: Automotive Assistance Application as a Motor Vehicle Service
![intro](https://drive.google.com/uc?export=view&id=1LQn2FzAv6g0mDD0gqElkAypqus7PXljI)
**URide** is a mobile application designed to help users efficiently manage and maintain their motorcycles or vehicles.  
The app addresses common challenges related to regular vehicle maintenance and promotes safer and more responsible driving habits.

Proper maintenance is essential not only for road safety both for the driver and others but also for prolonging the vehicle’s lifespan.  
URide provides an integrated solution that simplifies these processes through its **vehicle maintenance services**, **reminder system**, and **digital service records**.

---

## Objective

URide aims to promote **responsible vehicle ownership** by encouraging timely maintenance and providing easy access to essential vehicle service information through a modern, user-friendly interface.

---

## Contributors

This project is developed collaboratively by a dedicated team of developers:

- William Bryan Pangestu - 5026231011
- Nailah Adlina	- 5026231068
- Muhammad Zaky Al Khair - 5026231069
- Kurnia Yufi Satrio Laksono - 5026231086
- Gusti Gratia Delpiera	- 5026231097
- Keisha Adisti Athaillah - 5026231137
- Kayla Putri Maharani - 5026231158 

---

## Architecture & Directory Structure 

```text
lib/
├── core/                  # Global Component (Shared)
│   ├── services/          # External Service call (Midtrans etc.)
│   └── widgets/           # Widget (Button, NavBar, Cards)
├── features/              # FEATURES MODULE (Main Workspace)
│   ├── auth/              # Splash Screen, SignIn/SignUp
│   ├── home/              # Homepage, Search
│   ├── order/             # Service Order Page
│   ├── profile/           # User Profile Page, Edit Profile
│   ├── spbu/              # SPBU Page
│   ├── vehicles/          # Vehicle Page, Add Vehicle
│   └── workshops/         # Bengkel Page
├── routes/                # Routing 
│   └── app_routes.dart
└── main.dart
```
---

## Environment Variables

This project uses environment variables for configuration. The actual `.env` file is **not included** in the repository for security reasons.

#### 1. Create `.env` file

Copy the provided example file:

```bash
cp .env.example .env
```

#### 2. Fill in the required values

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
MAPS_API_KEY=your_google_maps_api_key
```

---

## Database Schema

The database design for **URide** follows a relational PostgreSQL schema optimized for integration with **Supabase Authentication** and mobile application workflows. An overview of the database structure, including table relationships and key entities (users, vehicles, workshops, orders, parking, and SPBU), can be seen in the following schema diagram:

![Database Schema](https://drive.google.com/uc?export=view&id=1VFkmc2HGX2xmdiWEhJwzEJ2r-T4sB7_b)

The complete **Data Definition Language (DDL)** script used to create the database schema is provided in the repository for reference and reproducibility. 
📁 **Location:**
```text
Script/db.sql
```
This file contains:
- Table definitions
- Primary and foreign key constraints
- Enum type definitions
- Referential integrity rules compatible with PostgreSQL & Supabase

> ⚠️ **Note:**  
> The DDL script is intended to be executed in a PostgreSQL environment (Supabase).  
> Any changes to the database structure should be reflected both in the schema diagram and the `db.sql` file to maintain consistency.
---
## Setup & Installation

Follow these steps to ensure that the local environment is suitable for development needs:

### Clone Repository

```bash
git clone https://github.com/gustigratia/URide
cd URide
```

### Install Dependencies

```bash
flutter pub get
```

### Environment Check

```bash
flutter analyze
```

### Run the program 

```bash
flutter run
```

---


## Contribution Guidelines

To avoid Merge Conflicts between team members, follow these rules:

### 1. Branch Rules

- ⛔ **DO NOT** push code directly to the `main` branch.
- ✅ Always create a new branch from `main` before starting to code.
- To create a new branch from GitHub projects, follow these steps:
  - Open issues on GitHub.
    
    ![Open Issues](https://drive.google.com/uc?export=view&id=1xL0X80lRx7Lhq7tQUBJPCbPT3N_vcG2s)
  - Open the issues to be worked on

    ![Open Issue](https://drive.google.com/uc?export=view&id=1klFYcGriqlvzfu70CJwJ21TQ-s1PNuQn)
  - Select “Create a branch” in the development section.

    ![Create a Branch](https://drive.google.com/uc?export=view&id=1uD0WxA5jXoIKlaIXXCE3rqw79CNXrO41)
  - Ensure the branch name follows the naming rule ([issue number]-issue), the destination is URide, the source branch is from main, and select “Checkout locally.” then Create Branch..

    ![Create branch](https://drive.google.com/uc?export=view&id=1popmXXlwJihOoxSBl-H1f-B4rot_KA0o)
  - Checkout in your local repository
    ```bash
    git fetch origin
    git checkout branch-name
    ```
  - Enjoy ur code... and don't forget to commit and push afterwards

### 2. Commit Rules

Use a standard format so that the change history is easy for the team to read (use English):

- `feat`: for new features (example: `feat: adding search queries logic`).
- `fix`: for bug fixes (example: `fix: fixing supabase auth errors`).
- `ui`: for changes to the appearance/widget (example: `ui: update the color of the save button`).
- `docs`: for documentation (example: `docs: update installation readme`).
- `refactor`: to tidy up the code without changing its functionality.

### 3. Workflow

1.  **Remote Repository Fetch:**

    ```bash
    git fetch origin
    ```

2.  **Buat Branch Kerja:**

    ```bash
    git checkout branch-name
    ```

3.  **Coding & Commit:**
    Make changes, then commit with a clear message.

    ```bash
    git add .
    git commit -m "feat: implement auth logic"
    ```

4.  **Push:**

    ```bash
    git push
    ```

5.  **Pull Request (PR):**
    Open GitHub, create a PR to `main`, and request a review from gustigratia.
    

---

## UI Design Credit

The original UI design for this application was created by 
**Tim Anti Badai (Institut Teknologi Sepuluh Nopember)**.

Some UI components used in the development have been modified or adjusted 
by the development team to fit the implementation requirements.

> Original UI Design by Muhammad Razan Parisya Putra, Muhammad Ade Dzakwan, and Azhar Aditya Pratama  
> [Original UI Design URide on Figma](https://www.figma.com/proto/irgoRWbKsUTcinAQKS0K2D/URide)

---

## Tech Stack

- **Frontend:** Flutter  
- **Backend (BaaS):** Supabase  
  - PostgreSQL Database  
  - Authentication (Supabase Auth)  
  - File Storage (Supabase Storage)  
  - Serverless Backend Logic (Supabase Edge Functions)  
- **Maps & Location Services:** Google Maps API  
- **AI Integration:** Gemini API (via Supabase Edge Functions)  
- **Payment Gateway:** Midtrans  
- **Version Control:** Git & GitHub  

---

## License

This project was developed as part of an academic assignment for the **Emerging Technology** course.  
It is intended solely for learning and research purposes within the field of automotive and mobility technology.  

If you wish to reuse or adapt any part of this codebase, please provide proper credit to the original developers and contributors.

---

_Techincal Documentation - URide Development Team © 2025_
