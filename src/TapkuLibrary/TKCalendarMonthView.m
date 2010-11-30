//
//  TKCalendarMonthView.m
//  Created by Devin Ross on 6/10/10.
//
/*
 
 tapku.com || http://github.com/devinross/tapkulibrary
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "TKCalendarMonthView.h"
#import "NSDate+TKCategory.h"
#import "TKGlobal.h"
#import "UIImage+TKCategory.h"

/*
#define kSun NSLocalizedString(@"Sun",@"Sun")
#define kMon NSLocalizedString(@"Mon",@"Mon")
#define kTue NSLocalizedString(@"Tue",@"Tue")
#define kWed NSLocalizedString(@"Wed",@"Wed")
#define kThu NSLocalizedString(@"Thu",@"Thu")
#define kFri NSLocalizedString(@"Fri",@"Fri")
#define kSat NSLocalizedString(@"Sat",@"Sat")
*/
#define kCalendImagesPath @"TapkuLibrary.bundle/Images/calendar/"



@interface TKCalendarMonthTiles : UIView {
	
	id target;
	SEL action;
	
	int firstOfPrev,lastOfPrev;
	NSArray *marks;
	int today;
	BOOL markWasOnToday;
	
	int selectedDay,selectedPortion;
	
	int firstWeekday, daysInMonth;
	UILabel *dot;
	UILabel *currentDay;
	UIImageView *selectedImageView;
	BOOL startOnSunday;
	NSDate *monthDate;
}
@property (readonly) NSDate *monthDate;

- (id) initWithMonth:(NSDate*)date marks:(NSArray*)marks startDayOnSunday:(BOOL)sunday;
- (void) setTarget:(id)target action:(SEL)action;

- (void) selectDay:(int)day;
- (NSDate*) dateSelected;

+ (NSArray*) rangeOfDatesInMonthGrid:(NSDate*)date startOnSunday:(BOOL)sunday;

@end

#define dotFontSize 18.0
#define dateFontSize 22.0

@interface TKCalendarMonthTiles (private)

@property (readonly) UIImageView *selectedImageView;
@property (readonly) UILabel *currentDay;
@property (readonly) UILabel *dot;
@end

@implementation TKCalendarMonthTiles
@synthesize monthDate;

+ (NSArray*) rangeOfDatesInMonthGrid:(NSDate*)date startOnSunday:(BOOL)sunday{
	
	NSDate *firstDate, *lastDate;
	
	TKDateInformation info = [date dateInformation];
	info.day = 1;
	NSDate *d = [NSDate dateFromDateInformation:info];
	info = [d dateInformation];
	
	if(info.weekday > 1){
		TKDateInformation info2 = info;
		
		
		info2.month--;
		if(info2.month<1) { info2.month = 12; info2.year--; }
		NSDate *previousMonth = [NSDate dateFromDateInformation:info2];
		int preDayCnt = [previousMonth daysInMonth];		
		info2.day = preDayCnt - info.weekday+2;
		
		firstDate = [NSDate dateFromDateInformation:info2];
		
		
		
	}else{
		firstDate = d;
	}
	
	
	
	
	int daysInMonth = [d daysInMonth];
	info.day = daysInMonth;
	NSDate *lastInMonth = [NSDate dateFromDateInformation:info];
	info = [lastInMonth dateInformation];
	if(info.weekday < 7){
		info.day = 7 - info.weekday;
		info.month++;
		if(info.month>12){
			info.month = 1;
			info.year++;
		}
		lastDate = [NSDate dateFromDateInformation:info];
	}else{
		lastDate = lastInMonth;
	}
	
	return [NSArray arrayWithObjects:firstDate,lastDate,nil];
}

- (id) initWithMonth:(NSDate*)date marks:(NSArray*)markArray startDayOnSunday:(BOOL)sunday{
	
	firstOfPrev = -1;
	marks = [markArray retain];
	monthDate = [date retain];
	startOnSunday = sunday;
	
	TKDateInformation dateInfo = [monthDate dateInformation];
	firstWeekday = dateInfo.weekday;
	daysInMonth = [date daysInMonth]; 
	int row = (daysInMonth + dateInfo.weekday - 1);
	row = (row / 7) + ((row % 7 == 0) ? 0:1);
	float h = 44 * row;
	
	TKDateInformation todayInfo = [[NSDate date] dateInformation];
	today = dateInfo.month == todayInfo.month && dateInfo.year == todayInfo.year ? todayInfo.day : 0;
	
	
	if(firstWeekday>1){
		dateInfo.month--;
		if(dateInfo.month<1) {
			dateInfo.month = 12;
			dateInfo.year--;
		}
		NSDate *previousMonth = [NSDate dateFromDateInformation:dateInfo];
		int preDayCnt = [previousMonth daysInMonth];		
		firstOfPrev = preDayCnt - firstWeekday+2;
		lastOfPrev = preDayCnt;
	}
	
	if(![super initWithFrame:CGRectMake(0, 1, 320, h+1)]) return nil;
	
	[self.selectedImageView addSubview:self.currentDay];
	[self.selectedImageView addSubview:self.dot];
	self.multipleTouchEnabled = NO;
	
	return self;
}
- (void) setTarget:(id)t action:(SEL)a{
	target = t;
	action = a;
}

- (CGRect) rectForCellAtIndex:(int)index{
	
	int row = index / 7;
	int col = index % 7;
	
	return CGRectMake(col*46, row*44+6, 47, 45);
}
- (void) drawTileInRect:(CGRect)r day:(int)day mark:(BOOL)mark font:(UIFont*)f1 font2:(UIFont*)f2{
	
	NSString *str = [NSString stringWithFormat:@"%d",day];
	
	
	r.size.height -= 2;
	[str drawInRect: r
		   withFont: f1
	  lineBreakMode: UILineBreakModeWordWrap 
		  alignment: UITextAlignmentCenter];
	
	if(mark){
		r.size.height = 10;
		r.origin.y += 18;
		
		[@"•" drawInRect: r
				withFont: f2
		   lineBreakMode: UILineBreakModeWordWrap 
			   alignment: UITextAlignmentCenter];
	}
	
	
}
- (void) drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIImage *tile = [UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile.png")];
	CGRect r = CGRectMake(0, 0, 46, 44);
	CGContextDrawTiledImage(context, r, tile.CGImage);
	
	if(today > 0){
		int pre = firstOfPrev > 0 ? lastOfPrev - firstOfPrev + 1 : 0;
		int index = today +  pre-1;
		CGRect r =[self rectForCellAtIndex:index];
		r.origin.y -= 7;
		[[UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Today Tile.png")] drawInRect:r];
	}
	
	int index = 0;
	
	UIFont *font = [UIFont boldSystemFontOfSize:dateFontSize];
	UIFont *font2 =[UIFont boldSystemFontOfSize:dotFontSize];
	UIColor *color = [UIColor grayColor];
	
	if(firstOfPrev>0){
		[color set];
		for(int i = firstOfPrev;i<= lastOfPrev;i++){
			r = [self rectForCellAtIndex:index];
			if ([marks count] > 0)
				[self drawTileInRect:r day:i mark:[[marks objectAtIndex:index] boolValue] font:font font2:font2];
			else
				[self drawTileInRect:r day:i mark:NO font:font font2:font2];
			index++;
		}
	}
	
	
	color = [UIColor colorWithRed:59/255. green:73/255. blue:88/255. alpha:1];
	[color set];
	for(int i=1; i <= daysInMonth; i++){
		
		r = [self rectForCellAtIndex:index];
		if(today == i) [[UIColor whiteColor] set];
		
		if ([marks count] > 0) 
			[self drawTileInRect:r day:i mark:[[marks objectAtIndex:index] boolValue] font:font font2:font2];
		else
			[self drawTileInRect:r day:i mark:NO font:font font2:font2];
		if(today == i) [color set];
		index++;
	}
	
	[[UIColor grayColor] set];
	int i = 1;
	while(index % 7 != 0){
		r = [self rectForCellAtIndex:index] ;
		if ([marks count] > 0) 
			[self drawTileInRect:r day:i mark:[[marks objectAtIndex:index] boolValue] font:font font2:font2];
		else
			[self drawTileInRect:r day:i mark:NO font:font font2:font2];
		i++;
		index++;
	}
	
	
}

- (void) selectDay:(int)day{
	
	int pre = firstOfPrev < 0 ?  0 : lastOfPrev - firstOfPrev + 1;
	
	int tot = day + pre;
	int row = tot / 7;
	int column = (tot % 7)-1;
	
	selectedDay = day;
	selectedPortion = 1;
	
	
	if(day == today){
		self.currentDay.shadowOffset = CGSizeMake(0, 1);
		self.dot.shadowOffset = CGSizeMake(0, 1);
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Today Selected Tile.png")];
		markWasOnToday = YES;
	}else if(markWasOnToday){
		self.dot.shadowOffset = CGSizeMake(0, -1);
		self.currentDay.shadowOffset = CGSizeMake(0, -1);
		
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile Selected.png")];
		markWasOnToday = NO;
	}
	
	
	
	[self addSubview:self.selectedImageView];
	self.currentDay.text = [NSString stringWithFormat:@"%d",day];
	
	if ([marks count] > 0) {
		
		if([[marks objectAtIndex: row * 7 + column ] boolValue]){
			[self.selectedImageView addSubview:self.dot];
		}else{
			[self.dot removeFromSuperview];
		}
		
		
	}else{
		[self.dot removeFromSuperview];
	}
	
	if(column < 0){
		column = 6;
		row--;
	}
	
	CGRect r = self.selectedImageView.frame;
	r.origin.x = (column*46);
	r.origin.y = (row*44)-1;
	self.selectedImageView.frame = r;
	
	
	
	
}
- (NSDate*) dateSelected{
	if(selectedDay < 1 || selectedPortion != 1) return nil;
	
	TKDateInformation info = [monthDate dateInformation];
	info.hour = 0;
	info.minute = 0;
	info.second = 0;
	info.day = selectedDay;
	NSDate *d = [NSDate dateFromDateInformation:info];
	
	
	//NSLog(@"%d %d %d %d %@",info.hour,info.minute,info.second,info.month,d);
	
	
	return d;
	
}



- (void) reactToTouch:(UITouch*)touch down:(BOOL)down{
	
	CGPoint p = [touch locationInView:self];
	if(p.y > self.bounds.size.height || p.y < 0) return;
	
	int column = p.x / 46, row = p.y / 44;
	int day = 1, portion = 0;
	
	if(row == (int) (self.bounds.size.height / 44)) row --;
	
	
	if(row==0 && column < firstWeekday-1){
		day = firstOfPrev + column;
	}else{
		portion = 1;
		day = row * 7 + column  - firstWeekday+2;
	}
	if(portion > 0 && day > daysInMonth){
		portion = 2;
		day = day - daysInMonth;
	}
	
	if(portion != 1){
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile Gray.png")];
		markWasOnToday = YES;
	}else if(portion==1 && day == today){
		self.currentDay.shadowOffset = CGSizeMake(0, 1);
		self.dot.shadowOffset = CGSizeMake(0, 1);
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Today Selected Tile.png")];
		markWasOnToday = YES;
	}else if(markWasOnToday){
		self.dot.shadowOffset = CGSizeMake(0, -1);
		self.currentDay.shadowOffset = CGSizeMake(0, -1);
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile Selected.png")];
		markWasOnToday = NO;
	}
	
	[self addSubview:self.selectedImageView];
	self.currentDay.text = [NSString stringWithFormat:@"%d",day];
	
	if ([marks count] > 0) {
		if([[marks objectAtIndex: row * 7 + column] boolValue])
			[self.selectedImageView addSubview:self.dot];
		else
			[self.dot removeFromSuperview];
	}else{
		[self.dot removeFromSuperview];
	}
	

	
	
	CGRect r = self.selectedImageView.frame;
	r.origin.x = (column*46);
	r.origin.y = (row*44)-1;
	self.selectedImageView.frame = r;
	
	if(day == selectedDay && selectedPortion == portion) return;
	
	
	
	if(portion == 1){
		selectedDay = day;
		selectedPortion = portion;
		[target performSelector:action withObject:[NSArray arrayWithObject:[NSNumber numberWithInt:day]]];
		
	}
	else if(down){
		[target performSelector:action withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:day],[NSNumber numberWithInt:portion],nil]];
		selectedDay = day;
		selectedPortion = portion;
	}
	
}
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	//[super touchesBegan:touches withEvent:event];
	[self reactToTouch:[touches anyObject] down:NO];
} 
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	[self reactToTouch:[touches anyObject] down:NO];
}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[self reactToTouch:[touches anyObject] down:YES];
}

- (UILabel *) currentDay{
	if(currentDay==nil){
		CGRect r = self.selectedImageView.bounds;
		r.origin.y -= 2;
		currentDay = [[UILabel alloc] initWithFrame:r];
		currentDay.text = @"1";
		currentDay.textColor = [UIColor whiteColor];
		currentDay.backgroundColor = [UIColor clearColor];
		currentDay.font = [UIFont boldSystemFontOfSize:dateFontSize];
		currentDay.textAlignment = UITextAlignmentCenter;
		currentDay.shadowColor = [UIColor darkGrayColor];
		currentDay.shadowOffset = CGSizeMake(0, -1);
	}
	return currentDay;
}
- (UILabel *) dot{
	if(dot==nil){
		CGRect r = self.selectedImageView.bounds;
		r.origin.y += 29;
		r.size.height -= 31;
		dot = [[UILabel alloc] initWithFrame:r];
		
		dot.text = @"•";
		dot.textColor = [UIColor whiteColor];
		dot.backgroundColor = [UIColor clearColor];
		dot.font = [UIFont boldSystemFontOfSize:dotFontSize];
		dot.textAlignment = UITextAlignmentCenter;
		dot.shadowColor = [UIColor darkGrayColor];
		dot.shadowOffset = CGSizeMake(0, -1);
	}
	return dot;
}
- (UIImageView *) selectedImageView{
	if(selectedImageView==nil){
		selectedImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamedTK:@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile Selected"]];
	}
	return selectedImageView;
}

- (void)dealloc {
	[currentDay release];
	[dot release];
	[selectedImageView release];
	[marks release];
	[monthDate release];
    [super dealloc];
}


@end



@interface TKCalendarMonthView (private)
@property (readonly) UIScrollView *tileBox;
@property (readonly) UIImageView *topBackground;
@property (readonly) UILabel *monthYear;
@property (readonly) UIButton *leftArrow;
@property (readonly) UIButton *rightArrow;
@property (readonly) UIImageView *shadow;

- (NSDate*) firstOfMonthFromDate:(NSDate*)date;
- (NSDate*) nextMonthFromDate:(NSDate*)date;
- (NSDate*) previousMonthFromDate:(NSDate*)date;

@end


@implementation TKCalendarMonthView (privateMeth)

- (NSDate*) firstOfMonthFromDate:(NSDate*)date{
	TKDateInformation info = [date dateInformation];
	info.day = 1;
	info.minute = 0;
	info.second = 0;
	info.hour = 0;
	return [NSDate dateFromDateInformation:info];
}
- (NSDate*) nextMonthFromDate:(NSDate*)date{
	
	
	TKDateInformation info = [date dateInformation];
	info.month++;
	if(info.month>12){
		info.month = 1;
		info.year++;
	}
	info.minute = 0;
	info.second = 0;
	info.hour = 0;
	
	return [NSDate dateFromDateInformation:info];
	
}
- (NSDate*) previousMonthFromDate:(NSDate*)date{
	
	
	TKDateInformation info = [date dateInformation];
	info.month--;
	if(info.month<1){
		info.month = 12;
		info.year--;
	}
	
	info.minute = 0;
	info.second = 0;
	info.hour = 0;
	return [NSDate dateFromDateInformation:info];
	
}

@end

@implementation TKCalendarMonthView
@synthesize delegate,dataSource;


- (id) init{
	return [self initWithSundayAsFirst:YES];
}
- (id) initWithSundayAsFirst:(BOOL)s{
	
	sunday = s;
	
	currentTile = [[[TKCalendarMonthTiles alloc] initWithMonth:[self firstOfMonthFromDate:[NSDate date]] 
														 marks:nil startDayOnSunday:YES] autorelease];
	[currentTile setTarget:self action:@selector(tile:)];
	
	[currentTile setTarget:self action:@selector(tile:)];
	CGRect r = CGRectMake(0, 0, self.tileBox.bounds.size.width, self.tileBox.bounds.size.height + self.tileBox.frame.origin.y);

	
	if (![super initWithFrame:r]) return nil;
	
	
	[currentTile retain];
	
	[self addSubview:self.topBackground];
	[self.tileBox addSubview:currentTile];
	[self addSubview:self.tileBox];
	
	NSDate *date = [NSDate date];
	self.monthYear.text = [NSString stringWithFormat:@"%@ %@",[date month],[date year]];
	[self addSubview:self.monthYear];
	
	
	[self addSubview:self.leftArrow];
	[self addSubview:self.rightArrow];
	
	[self addSubview:self.shadow];
	self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);
	
	self.backgroundColor = [UIColor grayColor];
	
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"eee"];
	
	
	
	
	NSString * sun = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:-3*60*60*24]];
	NSString * mon = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:-2*60*60*24]];
	NSString * tue = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:-1*60*60*24]];
	NSString * wed = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]];
	NSString * thu = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:60*60*24*1]];
	NSString * fri = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:60*60*24*2]];
	NSString * sat = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:60*60*24*3]];
	
	[dateFormat release];

	
	//NSLog(@"Day of the week: %@", weekdayString);
	
	//NSDate *d = [TKDateInformation dateWithInformation:testDate];
	
	
	
	NSArray *ar;
	if(sunday) ar = [NSArray arrayWithObjects:sun,mon,tue,wed,thu,fri,sat,nil];
	else ar = [NSArray arrayWithObjects:mon,tue,wed,thu,fri,sat,sun,nil];
	int i = 0;
	for(NSString *s in ar){
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(46 * i, 30, 46, 15)];
		[self addSubview:label];
		label.text = s;
		label.textAlignment = UITextAlignmentCenter;
		label.shadowColor = [UIColor whiteColor];
		label.shadowOffset = CGSizeMake(0, 1);
		label.font = [UIFont systemFontOfSize:11];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor colorWithRed:59/255. green:73/255. blue:88/255. alpha:1];

		i++;
		[label release];
	}
	
	return self;
}

- (void) changeMonthAnimation:(UIView*)sender{
	
	BOOL isNext = (sender.tag == 1);
	NSDate *nextMonth = isNext ? [self nextMonthFromDate:currentTile.monthDate] : [self previousMonthFromDate:currentTile.monthDate];
	
	NSArray *dates = [TKCalendarMonthTiles rangeOfDatesInMonthGrid:nextMonth startOnSunday:sunday];
	NSArray *ar = [dataSource calendarMonthView:self marksFromDate:[dates objectAtIndex:0] toDate:[dates lastObject]];
	TKCalendarMonthTiles *newTile = [[TKCalendarMonthTiles alloc] initWithMonth:nextMonth marks:ar startDayOnSunday:sunday];
	[newTile setTarget:self action:@selector(tile:)];
	
	
	
	int overlap =  0;
	
	if(isNext){
		overlap = [newTile.monthDate isEqualToDate:[dates objectAtIndex:0]] ? 0 : 44;
	}else{
		overlap = [currentTile.monthDate compare:[dates lastObject]] !=  NSOrderedDescending ? 44 : 0;
	}
	
	float y = isNext ? currentTile.bounds.size.height - overlap : newTile.bounds.size.height * -1 + overlap;
	
	newTile.frame = CGRectMake(0, y, newTile.frame.size.width, newTile.frame.size.height);
	[self.tileBox addSubview:newTile];
	[self.tileBox bringSubviewToFront:currentTile];
	
	
	
	
	self.userInteractionEnabled = NO;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDidStopSelector:@selector(animationEnded)];
	[UIView setAnimationDuration:0.4];
	
	currentTile.alpha = 0.0;
	
	if(isNext){
		
		currentTile.frame = CGRectMake(0, -1 * currentTile.bounds.size.height + overlap, currentTile.frame.size.width, currentTile.frame.size.height);
		newTile.frame = CGRectMake(0, 1, newTile.frame.size.width, newTile.frame.size.height);
		self.tileBox.frame = CGRectMake(self.tileBox.frame.origin.x, self.tileBox.frame.origin.y, self.tileBox.frame.size.width, newTile.frame.size.height);
		self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.bounds.size.width, self.tileBox.frame.size.height+self.tileBox.frame.origin.y);
		
		self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);
		
		
	}else{
		
		newTile.frame = CGRectMake(0, 1, newTile.frame.size.width, newTile.frame.size.height);
		self.tileBox.frame = CGRectMake(self.tileBox.frame.origin.x, self.tileBox.frame.origin.y, self.tileBox.frame.size.width, newTile.frame.size.height);
		self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.bounds.size.width, self.tileBox.frame.size.height+self.tileBox.frame.origin.y);
		currentTile.frame = CGRectMake(0,  newTile.frame.size.height - overlap, currentTile.frame.size.width, currentTile.frame.size.height);
		
		self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);
		
		
		
	}
	
	
	[UIView commitAnimations];
	
	oldTile = currentTile;
	currentTile = newTile;
	monthYear.text = [NSString stringWithFormat:@"%@ %@",[nextMonth month],[nextMonth year]];
	
	

}

- (void) changeMonth:(UIButton *)sender{
	
	[self changeMonthAnimation:sender];
	if([delegate respondsToSelector:@selector(calendarMonthView:monthDidChange:)])
		[delegate calendarMonthView:self monthDidChange:currentTile.monthDate];

}
- (void) animationEnded{
	self.userInteractionEnabled = YES;
	[oldTile release];
	oldTile = nil;
}

- (NSDate*) dateSelected{
	return [currentTile dateSelected];
}
- (NSDate*) monthDate{
	return [currentTile monthDate];
}
- (void) selectDate:(NSDate*)date{
	TKDateInformation info = [date dateInformation];
	NSDate *month = [self firstOfMonthFromDate:date];
	
	if([month isEqualToDate:[currentTile monthDate]]){
		[currentTile selectDay:info.day];
		return;
	}else {
		
		NSDate *month = [self firstOfMonthFromDate:date];
		NSArray *dates = [TKCalendarMonthTiles rangeOfDatesInMonthGrid:month startOnSunday:sunday];
		NSArray *data = [dataSource calendarMonthView:self marksFromDate:[dates objectAtIndex:0] toDate:[dates lastObject]];
		TKCalendarMonthTiles *newTile = [[TKCalendarMonthTiles alloc] initWithMonth:month 
																			  marks:data 
																   startDayOnSunday:sunday];
		[newTile setTarget:self action:@selector(tile:)];
		[currentTile removeFromSuperview];
		[currentTile release];
		currentTile = newTile;
		[self.tileBox addSubview:currentTile];
		self.tileBox.frame = CGRectMake(0, 44, newTile.frame.size.width, newTile.frame.size.height);
		self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.bounds.size.width, self.tileBox.frame.size.height+self.tileBox.frame.origin.y);

		self.shadow.frame = CGRectMake(0, self.frame.size.height-self.shadow.frame.size.height+21, self.shadow.frame.size.width, self.shadow.frame.size.height);

	
		self.monthYear.text = [NSString stringWithFormat:@"%@ %@",[month month],[month year]];
		
		[currentTile selectDay:info.day];
		
		
		
	}
}
- (void) reload{
	NSArray *dates = [TKCalendarMonthTiles rangeOfDatesInMonthGrid:[currentTile monthDate] startOnSunday:sunday];
	NSArray *ar = [dataSource calendarMonthView:self marksFromDate:[dates objectAtIndex:0] toDate:[dates lastObject]];
	
	TKCalendarMonthTiles *refresh = [[[TKCalendarMonthTiles alloc] initWithMonth:[currentTile monthDate] marks:ar startDayOnSunday:YES] autorelease];
	[refresh setTarget:self action:@selector(tile:)];
	
	[self.tileBox addSubview:refresh];
	[currentTile removeFromSuperview];
	[currentTile release];
	currentTile = [refresh retain];
	
}

- (void) tile:(NSArray*)ar{
	
	if([ar count] < 2){
		
		NSDate *d = [currentTile monthDate];
		TKDateInformation info = [d dateInformation];
		info.day = [[ar objectAtIndex:0] intValue];
		
		NSDate *select = [NSDate dateFromDateInformation:info];
		if([delegate respondsToSelector:@selector(calendarMonthView:didSelectDate:)])
			[delegate calendarMonthView:self didSelectDate:select];
	}else{
		
		int direction = [[ar lastObject] intValue];
		UIButton *b = direction > 1 ? self.rightArrow : self.leftArrow;
		
		
		[self changeMonthAnimation:b];
		
		int day = [[ar objectAtIndex:0] intValue];
		//[currentTile selectDay:day];
	
		// thanks rafael
		TKDateInformation info = [[currentTile monthDate] dateInformation];
		info.day = day;
		NSDate *dateForMonth = [NSDate  dateFromDateInformation:info]; 
		[currentTile selectDay:day];
		
		if([delegate respondsToSelector:@selector(calendarMonthView:monthDidChange:)])
			[delegate calendarMonthView:self monthDidChange:dateForMonth];

		
	}
	
}


- (UIImageView *) topBackground{
	if(topBackground==nil){
		topBackground = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Grid Top Bar.png")]];
	}
	return topBackground;
}
- (UILabel *) monthYear{
	if(monthYear==nil){
		monthYear = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tileBox.frame.size.width, 38)];
		
		monthYear.textAlignment = UITextAlignmentCenter;
		monthYear.backgroundColor = [UIColor clearColor];
		monthYear.font = [UIFont boldSystemFontOfSize:22];
		monthYear.textColor = [UIColor colorWithRed:59/255. green:73/255. blue:88/255. alpha:1];
	}
	return monthYear;
}
- (UIButton *) leftArrow{
	if(leftArrow==nil){
		leftArrow = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		leftArrow.tag = 0;
		[leftArrow addTarget:self action:@selector(changeMonth:) forControlEvents:UIControlEventTouchUpInside];
		
		
		

		[leftArrow setImage:[UIImage imageNamedTK:@"TapkuLibrary.bundle/Images/calendar/Month Calendar Left Arrow"] forState:0];
		
		leftArrow.frame = CGRectMake(0, 0, 48, 38);
	}
	return leftArrow;
}
- (UIButton *) rightArrow{
	if(rightArrow==nil){
		rightArrow = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		rightArrow.tag = 1;
		[rightArrow addTarget:self action:@selector(changeMonth:) forControlEvents:UIControlEventTouchUpInside];
		rightArrow.frame = CGRectMake(320-45, 0, 48, 38);
		


		[rightArrow setImage:[UIImage imageNamedTK:@"TapkuLibrary.bundle/Images/calendar/Month Calendar Right Arrow"] forState:0];
		
	}
	return rightArrow;
}
- (UIScrollView *) tileBox{
	if(tileBox==nil){
		tileBox = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 44, 320, currentTile.frame.size.height)];
	}
	return tileBox;
}
- (UIImageView *) shadow{
	if(shadow==nil){
		shadow = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Shadow.png")]];
	}
	return shadow;
}

- (void)dealloc {
	[shadow release];
	[topBackground release];
	[leftArrow release];
	[monthYear release];
	[rightArrow release];
	[tileBox release];
	[currentTile release];
    [super dealloc];
}


@end
