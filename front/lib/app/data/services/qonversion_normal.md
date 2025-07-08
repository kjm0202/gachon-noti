Displaying Products
Manage promoted in-app purchases in your app without releasing a new app version

Qonversion SDK provides flexible cross-platform in-app purchase management for your app. You don't need to save App Stores product IDs and respective prices on the client side.
To manage in-app products promoted in your app from the Qonversion dashboard, you need to configure Products, Entitlements and Offerings in Qonversion.

Once you have everything configured, Qonversion provides two ways of displaying products:

with Qonversion Offerings (recommended)
with Qonversion Products directly
We strongly recommend using Qonversion Offerings. This allows you to:

Change products offered to your users without app release
Run A/B tests
👍
Local cache

Qonversion SDK caches the data on products, offerings, and entitlements. This data is available when the internet connection is lost or there are server-side delays. Every time your application launches, SDK requests actual SkProduct/SkuDetails from the App Store or Google Play to get the most up-to-date product data.

Displaying Products
Use the offerings method to get the wrapper object Offerings:

try {
  final QOfferings offerings = await Qonversion.getSharedInstance().offerings();
  final List<QProduct> products = offerings.main.products;
  if (products.isNotEmpty) {
    // Display your products
  }
} catch (e) {
  print(e);
}
The products are listed in the same order as they were added to the Qonversion Offerings settings.

Additionally, in the the same settings, you can mark an offering as a main. That allows you to avoid keeping the Offering ID in your code. Nonetheless, you can still get an offering by ID (see below).

Qonversion Offerings
Qonversion Offerings

Qonversion.Product contains the following data:

Property

Description

qonversionID

Qonversion product ID. For example, main

storeID

App Stores Product ID

basePlanID

*Android only**. Identifier of the base plan for subscription product.
type

Product type. It can have the following values:

trial– Subscription with a trial period
intro - Subscription with an intro period
directSubscription/subscription– Auto-renewable or prepaid (Android) subscription without a trial or an intro
oneTime/inapp– Non-recurring product
duration (deprecated)

*iOS only**.
Duration of a product. It can have the following values:
unknown – for non-renewable purchases
weekly
monthly
3Months
6Months
annual
Please note, there is no 2-month duration option since Google Play does not have that option. Qonversion Product is designed to support cross-platform in-app purchases.

This field is deprecated. UsesubscriptionPeriod instead.

subscriptionPeriod

Subscription period for the product. Nil if the product is not a subscription.
SubscriptionPeriod object contains two fields:
SubscriptionPeriodUnitthat may be day/week/month/yearand IntegerunitCount.
For example, SubscriptionPeriodUnit = .month and unitCount = 3 indicate that the subscription duration is 3 months.
On Android and Cross-platform SDKs, there is also an iso field representing duration in ISO 8601 format, e.g. "P3M" for the above example.

trialDuration (deprecated)

*iOS only**.
Duration of an introductory offer. It can have the following values:
notAvailable - trial period is not available,
unknown - no information about a trial period,
threeDays
week
twoWeeks
month
twoMonths
threeMonths
sixMonths
year
other - for cases when the duration is not from the enum range. Depending on OS, you can check the trial duration directly from the product's skuDetails or skProduct.
This field is deprecated. UsetrialPeriod instead.

trialPeriod

Trial period for the product. Nil if the product is not a subscription or trial not available.
SubscriptionPeriod object contains two fields:
SubscriptionPeriodUnitthat may be day/week/month/yearand IntegerunitCount.
For example, SubscriptionPeriodUnit = .day and unitCount = 7 indicate that the
trial duration is 7 days.
On Android and Cross-platform SDKs, there is also an iso field representing duration in ISO 8601 format, e.g. "P3M" for the above example.

skProduct

*iOS only**. Contains SKProduct object received from StoreKit.
skuDetail

*Android only**. Contains skuDetails object received from Google Billing Client.
This field is deprecated. UsestoreDetails instead.

storeDetails

*Android only**. Describes the store details of the product, containing all the information from Google Play including the offers for purchasing the base plan of this product (specified by basePlanID) in case of a subscription.
The complete description can be found on this page.
prettyPrice

A localized product price with currency symbol provided by Apple or Google.
It can be displayed to a user. For example, $99.99

Get Offering by ID
You can request the specific offering using its ID:



try {
  final QOfferings offerings = await Qonversion.getSharedInstance().offerings();
  final QOffering discount = offerings.offeringForIdentifier("discount");
  if (discount != null) {
    // Offering is available
    // Display products
  }
} catch (e) {
  print(e);
}
Get The List of Available Products
Use the products method to get the list of the products available:



try {
  final Map<String, QProduct> products = await Qonversion.getSharedInstance().products();
} catch (e) {
  print(e);
}
The method returns the following two vars:

productsList – dictionary with available products
error - error
Qonversion Product IDs are the keys to the products' dictionary objects.
The values are the objects of the Qonversion.Product class.

Trial and introductory offer eligibility
You can check if a user is eligible for an introductory offer, including a free trial. It is calculated differently for iOS and Android users.

On iOS, users who have not previously used an introductory offer for any products in the same subscription group are eligible for an introductory offer.

On Android, eligibility is computed based on the store details. If Google Play Billing Library returned any of the trial or intro offers as a possible purchase option for a specific product, then it means that the user is eligible for it.

You can show only a regular price for users not eligible for an introductory offer.
Use the following function to determine eligibility:



try {
  final Map<String, QEligibility> eligibility = await Qonversion.getSharedInstance().checkTrialIntroEligibility(['main', 'premium']);
  final QEligibility mainProductStatus = eligibility['main'];
  if (mainProductStatus.status == QEligibilityStatus.eligible) {
      // handle available trial
  }
} catch (e) {
  print(e);
}

Making Purchases
Make in-app purchases with Qonversion SDK

Make sure to configure Products, Entitlements and Offerings in the Qonversion dashboard before you start handling purchases with Qonversion SDK:

1. Make a purchase
When Products and Entitlements are set, you can start making purchases with thepurchaseProduct method for iOS and cross-platform SDKs, and purchase for Android



try {
  final Map<String, QEntitlement> entitlements = await Qonversion.getSharedInstance().purchaseProduct(product);
} on QPurchaseException catch (e) {
  if (e.isUserCancelled) {
    // Purchase canceled by the user
  }
  print(e);
}
Where "product" is the Qonversion Product created in the Dashboard. See the previous step to display Products.

1.1. Define a specific offer (Android only)
Google Play Billing Library allows you to sell a subscription with different offers. You can get information about available offers from QProduct.storeDetails. Use one of the following options to provide the chosen offer for the purchase.

Java
Kotlin
Flutter
React Native
Unity
Cordova
Capacitor

// Specify the concrete offer:
var productOfferDetails = ... // Choose an offer from `storeDetails`
var purchaseOptions = QPurchaseOptionsBuilder()
    .setOffer(productOfferDetails)
    .build()

// or specify only the offer ID:
var purchaseOptions = QPurchaseOptionsBuilder()
    .setOfferId('offer_id')
    .build()

// and then provide created `QPurchaseOptions` to the `purchase` method:
var entitlements = await Qonversion.getSharedInstance().purchaseProduct(
    product,
    purchaseOptions: purchaseOptions
);
If provided, we will try to find and purchase the offer with the specified ID for the requested Qonversion product. If there is no offer with the specified ID, an error will be returned. If no offer ID is provided for the subscription purchase of Qonversion product with a specified base plan ID, then we will choose the most profitable offer for the client from all the available offers. We calculate the cheapest price for the client by comparing all the trial or intro phases and the base plan. For old Qonversion products (where the base plan ID is not specified), as well as for in-app products, the offer ID is ignored.

You can also remove any intro/trial offer from the purchase (to keep only a base plan). For that purpose, you should call removeOffer method of purchase options builder:

Java
Kotlin
Flutter
React Native
Unity
Cordova
Capacitor

var purchaseOptions = QPurchaseOptionsBuilder()
    .removeOffer()
    .build()
2. Handle a purchase result
The product purchase method returns a dictionary with the user's entitlements on success (either via callback/completion block or as return value depending on the platform). If something goes wrong, the method returns an error or throws an exception with the failure description.

There is aisCancelled flag available, which equals true if a user cancels the purchasing process on iOS and Unity. You can check the same behavior for Android by comparing the error code with theQonversionErrorCode.PurchaseCanceled. For Flutter and React-Native, there is an additional field in the thrown exception for that purpose (see the code examples above).

Entitlement IDs are the keys to the entitlements dictionary.
The values are the objects of the Qonversion.Entitlement class.

3. Update purchases (Android only)
Upgrading, downgrading, or changing a subscription on Google Play Store requires setting additional options through the PurchaseOptions builder.
See Google Play Documentation for more details.

Java
Kotlin
Flutter
React Native
Unity
Cordova
Capacitor

var purchaseOptions = QPurchaseOptionsBuilder()
    .setOldProduct(oldProduct)
    .build();
var entitlements = await Qonversion.getSharedInstance().purchaseProduct(
    product,
    purchaseOptions: purchaseOptions
);
Also, Qonversion supports providing any replacement mode for the old purchase. Just provide the necessary purchase update policy while building purchase options as follows:

Java
Kotlin
Flutter
React Native
Unity
Cordova
Capacitor

var purchaseOptions = QPurchaseOptionsBuilder()
    .setOldProduct(oldProduct)
    .setUpdatePolicy(QPurchaseUpdatePolicy.withTimeProration)
    .build();
Purchase update policy can be one of the following values:

Name	Description
ChargeFullPrice	The new plan takes effect immediately, and the user is charged full price of new plan and is given a full billing cycle of subscription, plus remaining prorated time from the old plan.
ChargeProratedPrice	The new plan takes effect immediately, and the billing cycle remains the same.
WithTimeProration	The new plan takes effect immediately, and the remaining time will be prorated and credited to the user.
Deferred	The new purchase takes effect immediately, the new plan will take effect when the old item expires.
WithoutProration	The new plan takes effect immediately, and the new price will be charged on next recurrence time.
The default update policy is WithTimeProration.

4. Multi-quantity purchases (iOS only)
When buying in-app products, you have the option to choose how many items you want to purchase. On Android, you can adjust the quantity directly in the purchase popup. However, on iOS, you’ll need to set the quantity beforehand. You can do it while building purchase options as follows:

Swift
Objective-C
Flutter
React Native
Unity
Cordova
Capacitor

var purchaseOptions = QPurchaseOptionsBuilder()
    .setQuantity(3)
    .build();
var entitlements = await Qonversion.getSharedInstance().purchaseProduct(
    product,
    purchaseOptions: purchaseOptions
);
5. Check user entitlements
Use the checkEntitlements() SDK method in case you want to check users’ entitlements separately from a purchase. Learn more here.

6. Restore purchases
When users, for example, upgrade to a new phone, they need to restore purchases so they can keep access to your premium features.

Call the restore() method to restore purchases:



try {
  final Map<String, QEntitlement> entitlements = await Qonversion.getSharedInstance().restore();
} catch (e) {
  print(e);
}

Subscription Status
Check subscription status and manage user access

You can check subscription status and manage user access to the premium content on your app by checking user entitlements with the checkEntitlements() method.

Entitlement is access to the premium features of your application.
→ Read more about creating and using entitlements here.

You need to call the checkEntitlements() method at the start of your app to check if a user has the required entitlement. This method will check the user's receipt and return current entitlements.

In addition, Qonversion can manage cross-platform entitlements with the User Identity concept (e.g. after your users subscribe using the IOS app, you can use Qonversion to check their entitlements in your Android or Web applications)

📘
Qonversion SDK caches all required data on products, offerings, and entitlements. The data is still immediately available when the internet connection is lost, or there are server-side delays.

🚧
Note, please, that the entitlement object is available only in case the user has made a purchase, or you granted the entitlement manually using the Customer tab or Grant Entitlement API. In other cases, you will receive an empty result.



try {
  final Map<String, QEntitlement> entitlements = await Qonversion.getSharedInstance().checkEntitlements();
  final premium = entitlements['premium'];
  if (premium != null && premium.isActive) {
    switch (premium.renewState) {
      case QEntitlementRenewState.willRenew:
      case QEntitlementRenewState.nonRenewable:
      // .willRenew is the state of an auto-renewable subscription
      // .nonRenewable is the state of consumable/non-consumable IAPs that could unlock lifetime access
        break;
      case QEntitlementRenewState.billingIssue:
      // Grace period: entitlement is active, but there was some billing issue.
      // Prompt the user to update the payment method.
        break;
      case QEntitlementRenewState.canceled:
      // The user has turned off auto-renewal for the subscription, but the subscription has not expired yet.
      // Prompt the user to resubscribe with a special offer.
        break;
      default:
        break;
    }
  }
} catch (e) {
  print(e);
}
The Entitlement Object
Var Name

Description

id

Qonversion entitlements ID. For example, premium

isActive

Boolean. true means a user has active entitlement.
Please note that isActive = true does not mean a subscription will be renewed. A user can have active entitlement while auto-renewal for the subscription is switched off.

source

Source of the purchase via which the entitlement was activated.
Values:
– appstore: App Store
– playstore: Play Store
– stripe: Stripe
– unknown: unable to detect the source
– manual: the entitlement was activated manually

startedDate

Initial transaction date. For a subscription with a trial period, the date will be when the trial starts.

trialStartDate

The trial start date for current entitlement.
Null for entitlement that was unlocked by consumable/non-consumable/lifetime purchase or subscription without a trial period.

firstPurchaseDate

The date of the first purchase.

lastPurchaseDate

The date of the last purchase.

autoRenewDisableDate

The date when auto-renew for the subscription was disabled.

expirationDate

The expiration date for a subscription.
Null for a consumable/non-consumable in-app purchase or a lifetime subscription

productId

Identifier of the product from the Qonversion Dashboard

renewState

A renewal state of the subscription. It can have the following values:
nonRenewable - consumable or non-consumable in-app purchase,
willRenew – subscription is active, and auto-renew status is on,
billingIssue – there was some billing issue,
canceled – the subscription was cancelled,
unknown - if we don't have information about the renewal state.

renewsCount

Subscription renews count for the entitlement. Renews count starts from the second paid transaction.
For example, we have 20 transactions:

The first one is the trial started transaction
The second one is the first paid transaction, trial converted.
All the other - subscription renew transactions, thus renewsCount is equal to 18.
grantType

Grant type of entitlement

purchase: User bought a subscription
-familySharing: User got entitlement via family sharing
offerCode: User got entitlement using offer code
manual: User got entitlement via Qonversion dashboard feature
lastActivatedOfferCode

The last activated offer code that unlocks the current entitlement.

transactions

An array of Transaction objects that contains information about transactions that unlocked current entitlement.

The Transaction object
Var Name

Description

originalTransactionId

The original transaction identifier.

transactionId

The transaction identifier.

offerCode

The offer code that was used to get the transactions.

transactionDate

The date of the transaction.

expirationDate

The expiration date for the transaction.
Null for a consumable/non-consumable in-app purchase or a lifetime subscription

transactionRevocationDate

The date when the transaction was revoked. This field represents the time and date the App Store refunded a transaction or revoked it from family sharing.

environment

The environment of the transaction:

sandbox
production
ownershipType

Type of the ownership for the transaction:

owner- User owns the transaction
familySharing- User got transaction via family sharing
type

Type of the transaction:

subscriptionStarted
subscriptionRenewed
trialStarted
introStarted
introRenewed
nonConsumablePurchase


Offline SDK mode
Qonversion SDKs work when there is no internet connection on the device, or Qonversion API is inaccessible for a short time. Please take a look at the details of this mode below.

Products and Offerings
The information about your Products and Offerings is crucial to show a paywall and create a purchase. Qonversion SDKs have a built-in cache that preprocesses this data and makes it available to help you offer top-notch UX for your customers.

Entitlements
Entitlements are the central part of subscription-based access management. Once your app user purchases using our SDK, the SDK returns the currently available subscription status or the cached status during a lack of internet connection or issues with Qonversion API. The cached subscription state is available for one month by default.

You can change the duration according to your needs while configuring Qonversion as follows:



final config = new QonversionConfigBuilder(
  	'projectKey',
  	QLaunchMode.subscriptionManagement
)
  	.setEntitlementsCacheLifetime(QEntitlementsCacheLifetime.year)
  	.build();
Qonversion.initialize(config);
Let's have a look at the following hypothetical example:

A user purchases a weekly subscription.
He sets off on a long journey without internet access. But he wants to continue using your premium features offline.
Qonversion SDK will be returning information that this particular user is eligible for premium access for one month if the user does not connect to the internet during this period.
Eventually, when he opens the app with an internet connection available, Qonversion will update subscription statuses and show the current state accordingly.
Purchases
Purchases are the third critical part of subscription management. We guarantee data completeness in this case as well.
If, for some reason, our SDK cannot complete the purchase through Qonversion API in real-time, the SDK stores the data on the device and resends it at the next app launch. Your users will have a seamless experience: even if we cannot get a response from our servers (network or API outages), we will locally determine entitlements (based on previously loaded information) and provide correct user access. Then, we will also update the eligibility with the first successful request to our API.




Google Play Product Details
Google Play products have a deeply nested structure of objects, containing different information. In our Android and Cross-platform SDKs, we have represented several wrapping classes, containing all the information received from Google Play Billing Library. Below are the specifications of those classes.

QProductStoreDetails class contains core information about the store product.

Field

Type

Description

originalProductDetails

ProductDetails

Original product details received from Google Play Billing Library.

basePlanId

String

Identifier of the base plan to which these details relate. Null for in-app products or if not specified in the Qonversion Dashboard.

productId

String

Identifier of the subscription or the in-app product.

name

String

Name of the subscription or the in-app product

title

String

Title of the subscription or the in-app product. The title includes the name of the app.

description

String

Description of the subscription or the in-app product.

subscriptionOfferDetails

QProductOfferDetails[]

Offer details for the subscription. Offer details contain all the available variations of purchase offers,
including both base plan and eligible base plan + offer combinations from Google Play Console for the current basePlanId. Null for in-app products or if basePlanId is not specified in the Qonversion Dashboard.

defaultSubscriptionOfferDetails

QProductOfferDetails

The most profitable subscription offer for the client in our opinion from all the available offers. We calculate the cheapest price for the client by comparing all the trial or intro phases along with the base plan.

basePlanSubscriptionOfferDetails

QProductOfferDetails

Subscription offer details containing only the base plan without any offer.

inAppOfferDetails

QProductInAppDetails

Offer details for the in-app product. Null for subscriptions.

hasTrialOffer

Boolean

True, if there is any eligible offer with a trial for this subscription and base plan combination. False otherwise or for an in-app product.

hasIntroOffer

Boolean

True, if there is any eligible offer with an intro price for this subscription and base plan combination. False otherwise or for an in-app product.

hasTrialOrIntroOffer

Boolean

True, if there is any eligible offer with a trial or an intro price for this subscription and base plan combination. False otherwise or for an in-app product.

productType

QProductType

The calculated type of the current product.

isInApp

Boolean

True, if the product type is InApp.

isSubscription

Boolean

True, if the product type is Subscription.

isPrepaid

Boolean

True, if the subscription product is prepaid, which means that users pay in advance - they will need to make a new payment to extend their plan.

QProductOfferDetails class contains all the information about the Google subscription offer details. It might be either a plain base plan details or a base plan with concrete offer details.

Field	Type	Description
originalOfferDetails	SubscriptionOfferDetails	Original subscription offer details received from Google Play Billing Library.
basePlanId	String	The identifier of the current base plan.
offerId	String	The identifier of the concrete offer, to which these details belong. Null, if these are plain base plan details.
offerToken	String	A token to purchase the current offer.
tags	String[]	List of tags set for the current offer.
pricingPhases	QProductPricingPhase[]	A time-ordered list of pricing phases for the current offer.
basePlan	QProductPricingPhase	A base plan phase details.
trialPhase	QProductPricingPhase	A trial phase details, if exists.
introPhase	QProductPricingPhase	An intro phase details, if exists. The intro phase is one of single or recurrent discounted payments.
hasTrial	Boolean	True, if there is a trial phase in the current offer. False otherwise.
hasIntro	Boolean	True, if there is any intro phase in the current offer. False otherwise. The intro phase is one of single or recurrent discounted payments.
hasTrialOrIntro	Boolean	True, if there is any trial or intro phase in the current offer. False otherwise. The intro phase is one of single or recurrent discounted payments.
QProductPricingPhase class represents a pricing phase, describing how a user pays at a point in time.

Field	Type	Description
originalPricingPhase	PricingPhase	Original pricing phase received from Google Play Billing Library
price	QProductPrice	Price for the current phase.
billingPeriod	QSubscriptionPeriod	The billing period for which the given price applies.
billingCycleCount	Int	Number of cycles for which the billing period is applied.
recurrenceMode	QProductPricingPhase.RecurrenceMode	Recurrence mode for the pricing phase.
type	QProductPricingPhase.Type	Type of the pricing phase.
isTrial	Boolean	True, if the current phase is a trial period. False otherwise.
isIntro	Boolean	True, if the current phase is an intro period. False otherwise. The intro phase is one of single or recurrent discounted payments.
isBasePlan	Boolean	True, if the current phase represents the base plan. False otherwise.
QSubscriptionPeriod class describes a subscription period.

Field	Type	Description
unitCount	Int	A count of subsequent intervals.
unit	QSubscriptionPeriod.Unit	Interval unit.
iso	String	ISO 8601 representation of the period, e.g. "P7D", meaning 7 days period.
QProductInAppDetails class contains all the information about the Google in-app product details.

Field	Type	Description
originalOneTimePurchaseOfferDetails	OneTimePurchaseOfferDetails	Original one-time purchase offer details received from Google Play Billing Library.
price	QProductPrice	The price of the in-app product.
QProductPrice class contains information about the product's price.

Field	Type	Description
priceAmountMicros	Long	Total amount of money in micro-units, where 1,000,000 micro-units equal one unit of the currency.
priceCurrencyCode	String	ISO 4217 currency code for price.
formattedPrice	String	Formatted price for the payment, including its currency sign.
isFree	Boolean	True, if the price is zero. False otherwise.
currency	Currency	Currency object from the priceCurrencyCode. Null if failed to parse.
currencySymbol	String	Price currency symbol. Null if failed to parse.
QSubscriptionPeriod.Unit is the enumeration of the following values: Day, Week, Month, Year, Unknown.

QProductPricingPhase.RecurrenceMode describes the recurrence mode of the pricing phase and contains the following values.

Value	Description
InfiniteRecurring	The billing plan payment recurs for infinite billing periods unless canceled.
FiniteRecurring	The billing plan payment recurs for a fixed number of billing periods.
NonRecurring	The billing plan payment is a one-time charge that does not repeat.
Unknown	Unknown recurrence mode.
QProductPricingPhase.Type describes the type of the pricing phase and contains the following values.

Value	Description
Regular	Regular subscription without any discounts like trial or intro offers.
FreeTrial	A free phase.
DiscountedSinglePayment	A phase with a discounted payment for a single period.
DiscountedRecurringPayment	A phase with a discounted payment for several periods.
Unknown	Unknown pricing phase type.