#pragma mark - Chat

#define kKATGChatURLString @"http://www.keithandthegirl.com/chat/chat.aspx"

#pragma mark - Data

#define kKATGShowEntityName @"Show"
#define kKATGImageEntityName @"Image"
#define kKATGGuestEntityName @"Guest"

#pragma mark - API

static NSString * const kReachabilityURL = @"app.keithandthegirl.com";

//static NSString * const kTestServerBaseURL = @"http://protected-savannah-5921.herokuapp.com";
static NSString * const kServerBaseURL = @"http://app.keithandthegirl.com/api/v2/";
static NSString * const kShowListURIAddress		=	@"shows/recent/";
static NSString * const kShowDetailsURIAddress	=	@"shows/details/?showid=%@";

static NSString * const kUpcomingURIAddress		=	@"events?sanitize=true";

static NSString * const kLiveShowStatusURIAddress = @"feed/live/";

static NSString * const kFeedbackURL = @"http://www.attackwork.com/Voxback/Comment-Form-Iframe.aspx";