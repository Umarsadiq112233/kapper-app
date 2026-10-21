# Kapper navigation

Launch → session state → role selection → phone → OTP → profile completion → role home.
Phone → password sign in → role home. OTP → edit phone or resend.

Customer home tabs: Dashboard / Inbox / Style preview (pushed route) / Appointments / Profile.
Vendor home tabs: Dashboard / Custom Styles / Inbox / Appointments / Profile. The dashboard metrics and schedule derive from the signed-in vendor's appointments and services; quick actions open service, availability, portfolio, appointments, messages, and salon-profile flows.
Tab bodies use IndexedStack to preserve their state.

Dashboard → Search → Filter dialog → Salon.
Salon → Services / Portfolio / Reviews.
Services → select service + date + time → Details dialog → Demo Payment → Confirmation → Appointments.
Payment decline remains on payment without adding a booking.
Appointments → Chat / Reschedule dialog / Cancel confirmation / Review (completed only).
Vendor appointments → Mark completed.
Profile → Favorites (customer) / Notifications / Settings / Transactions / About / Edit / Logout.
Transactions → Details. Notifications → Appointments or matching Chat.

Vendor salon → Availability → Add/Edit/Delete Date; Add/Select/Edit/Delete Time → Save.
Vendor salon → Add/Edit Service dialog → Save.
Vendor portfolio → Upload → Select/Create Album → Save.
Vendor styles → Create Style dialog → Save.

All named routes are registered in lib/main.dart with reduced-motion-aware fade/slide transitions. Signed-out protected routes return to role selection; customer requests for /vendor/* return to home. Chat routes validate appointment IDs and vendor ownership. Booking confirmation requires an existing booking. Unknown routes recover to home. Demo sign out preserves catalog/booking data so the two roles can be explored in one process.
