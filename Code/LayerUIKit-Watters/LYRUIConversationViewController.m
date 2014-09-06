//
//  LYRUIConversationViewController.m
//  LayerSample
//
//  Created by Kevin Coleman on 8/31/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "LYRUIConversationViewController.h"
#import "LYRUIMessageCollectionViewCell.h"

@interface LYRUIConversationViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) LYRClient *layerClient;
@property (nonatomic, strong) LYRConversation *conversation;
@property (nonatomic, strong) NSOrderedSet *messages;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIViewController *inputToolbar;
@property (nonatomic) BOOL keyboardIsOnScreen;

@end

@implementation LYRUIConversationViewController

static NSString *const LYRUIMessageCellIdentifier = @"messageCellIdentifier";
static NSString *const LSMessageHeaderIdentifier = @"headerViewIdentifier";
static CGFloat const LSComposeViewHeight = 40;

+ (instancetype)conversationViewControllerWithConversation:(LYRConversation *)conversation layerClient:(LYRClient *)layerClient;
{
    return [[self alloc] initWithConversation:conversation layerClient:layerClient];
}

- (id)initWithConversation:(LYRConversation *)conversation layerClient:(LYRClient *)layerClient
{
    self = [super init];
    if (self) {
        
        NSAssert(layerClient, @"`self.layerController` cannot be nil");
        NSAssert(conversation, @"`self.conversation` cannont be nil");
        
        self.title = @"Conversation";
        self.accessibilityLabel = @"Conversation";
        
        self.conversation = conversation;
        self.layerClient = layerClient;
        
    }
    return self;
}
    
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup Collection View
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                             collectionViewLayout:flowLayout];
    
    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 40, 0);
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.alwaysBounceVertical = TRUE;
    self.collectionView.bounces = TRUE;
    self.collectionView.accessibilityLabel = @"collectionView";
    [self.view addSubview:self.collectionView];
    [self.collectionView registerClass:[LYRUIMessageCollectionViewCell class] forCellWithReuseIdentifier:LYRUIMessageCellIdentifier];
    //[self.collectionView registerClass:[LSMessageCellHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:LSMessageHeaderIdentifier];
    
    // Setup Compose View
    self.composeViewController = [[UIViewController alloc] init];
    self.composeViewController.view.frame = CGRectMake(0, 100, 320, 40);
    [self addChildViewController:self.composeViewController];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self fetchMessages];
    [self.collectionView reloadData];
    [self scrollToBottomOfCollectionViewAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    self.keyboardIsOnScreen = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)fetchMessages
{
    NSAssert(self.conversation, @"Conversation should not be `nil`.");
    if (self.messages) self.messages = nil;
    self.messages = [self.layerClient messagesForConversation:self.conversation];
}

- (void)dealloc
{
    self.collectionView.delegate = nil;
}

# pragma mark
# pragma mark Collection View Data Source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[[self.messages objectAtIndex:section] parts] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.messages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LYRUIMessageCollectionViewCell  *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:LYRUIMessageCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    //[self markMessageAtIndexPathAsRead:indexPath];
    return cell;
}

- (void)configureCell:(LYRUIMessageCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
//    LSMessageCellPresenter *presenter = [LSMessageCellPresenter presenterWithMessages:self.messages indexPath:indexPath persistanceManager:self.persistanceManager];
//    [self updateRecipientStatusForMessage:presenter.message];
//    [cell updateWithPresenter:presenter];
}

- (void)markMessageAtIndexPathAsRead:(NSIndexPath *)indexPath
{
    LYRMessage *message = [self.messages objectAtIndex:indexPath.section];
    NSNumber *recipientStatus = [message.recipientStatusByUserID objectForKey:self.layerClient.authenticatedUserID];
    if (![recipientStatus isEqualToNumber:[NSNumber numberWithInteger:LYRRecipientStatusRead]] ) {
        NSError *error;
        BOOL success = [self.layerClient markMessageAsRead:message error:&error];
        if (success) {
            NSLog(@"Message successfully marked as read");
        } else {
            NSLog(@"Failed to mark message as read with error %@", error);
        }
    }
}

#pragma mark
#pragma mark Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Nothing to do for now
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LYRMessage *message = [self.messages objectAtIndex:indexPath.section];
    LYRMessagePart *part = [message.parts objectAtIndex:indexPath.row];
    return CGSizeMake(320, 10);
}

- (UIEdgeInsets)collectionView: (UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 6, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
//{
//    LSMessageCellHeader *header = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:LSMessageHeaderIdentifier forIndexPath:indexPath];
//    if (kind == UICollectionElementKindSectionHeader ) {
//        LSMessageCellPresenter *presenter = [LSMessageCellPresenter presenterWithMessages:self.messages indexPath:indexPath persistanceManager:self.persistanceManager];
//        if ([presenter shouldShowSenderLabel] && [presenter shouldShowTimeStamp]) {
//            [header updateWithSenderName:[presenter labelForMessageSender] timeStamp:presenter.message.sentAt];
//        } else if ([presenter shouldShowSenderLabel]) {
//            [header updateWithSenderName:[presenter labelForMessageSender] timeStamp:nil];
//        } else if ([presenter shouldShowTimeStamp]) {
//            [header updateWithSenderName:nil timeStamp:presenter.message.receivedAt];
//        }
//    }
//    return header;
//}
//
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
//{
//    CGRect bounds = [[UIScreen mainScreen] bounds];
//    LSMessageCellPresenter *presenter = [LSMessageCellPresenter presenterWithMessages:self.messages indexPath:[NSIndexPath indexPathForItem:0 inSection:section] persistanceManager:self.persistanceManager];
//    if ([presenter shouldShowSenderLabel] && [presenter shouldShowTimeStamp]) {
//        return CGSizeMake(bounds.size.width, 60);
//    } else if ([presenter shouldShowSenderLabel]) {
//        return CGSizeMake(bounds.size.width, 40);
//    } else if ([presenter shouldShowTimeStamp]) {
//        return CGSizeMake(bounds.size.width, 40);
//    }
//    return CGSizeZero;
//}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeZero;
}

# pragma mark
# pragma mark Cell UI Configuration Methods
//- (void)updateRecipientStatusForMessage:(LYRMessage *)message
//{
//    NSString *identifier = self.APImanager.authenticatedSession.user.userID;
//    LYRRecipientStatus status = [message recipientStatusForUserID:identifier];
//    if (status == LYRRecipientStatusDelivered) {
//        [self.layerClient markMessageAsRead:message error:nil];
//    }
//}

#pragma mark
#pragma mark Keyboard Nofifications

- (void)keyboardWasShown:(NSNotification*)notification
{
    self.keyboardIsOnScreen = TRUE;
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
//    self.keyboardHeight = kbSize.height;
    //[self updateInsets];
    
    //self.composeView.frame = CGRectMake(self.composeView.frame.origin.x, self.composeView.frame.origin.y - kbSize.height, self.composeView.frame.size.width, self.composeView.frame.size.height);
    [self.collectionView setContentOffset:[self bottomOffset]];
    
    [UIView commitAnimations];
    
    self.keyboardIsOnScreen = TRUE;
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    //self.keyboardHeight = 0;
    //[self updateInsets];
    
    //self.composeView.frame = CGRectMake(self.composeView.frame.origin.x, self.composeView.frame.origin.y + kbSize.height, self.composeView.frame.size.width, self.composeView.frame.size.height);
    [UIView commitAnimations];
    
    self.keyboardIsOnScreen = FALSE;
    //[self composeViewShouldRestFrame:nil];
}

#pragma mark
#pragma mark LSComposeViewDelegate

//- (void)composeView:(LSComposeView *)composeView sendMessageWithText:(NSString *)text
//{
//    LYRMessagePart *part = [LYRMessagePart messagePartWithText:text];
//    LYRMessage *message = [LYRMessage messageWithConversation:self.conversation parts:@[ part ]];
//    
//    NSString *senderName = [self.persistanceManager persistedSessionWithError:nil].user.fullName;
//    NSString *pushText = [NSString stringWithFormat:@"%@: %@", senderName, text];
//    [self.layerClient setMetadata:@{LYRMessagePushNotificationAlertMessageKey: pushText} onObject:message];
//    
//    NSError *error;
//    BOOL success = [self.layerClient sendMessage:message error:&error];
//    if (success) {
//        NSLog(@"Messages Succesfully Sent");
//    } else {
//        NSLog(@"The error is %@", error);
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Messaging Error"
//                                                            message:[error localizedDescription]
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//        [alertView show];
//    }
//}
//
//- (void)composeViewShouldRestFrame:(LSComposeView *)composeView
//{
//    if (!self.keyboardIsOnScreen) {
//        CGRect rect = [[UIScreen mainScreen] bounds];
//        [self.composeView setFrame:CGRectMake(0, rect.size.height - 40, rect.size.width, 40)];
//    }
//}
//
//- (void)composeView:(LSComposeView *)composeView setComposeViewHeight:(CGFloat)height
//{
//    if (height < 135 && height != self.composeView.frame.size.height) {
//        CGFloat yOriginOffset = composeView.frame.size.height - height;
//        [self.composeView setFrame:CGRectMake(0, composeView.frame.origin.y + yOriginOffset, self.view.frame.size.width, height)];
//        [self updateInsets];
//        [self scrollToBottomOfCollectionViewAnimated:YES];
//    }
//}
//
//- (void)composeView:(LSComposeView *)composeView sendMessageWithImage:(UIImage *)image
//{
//    UIImage *adjustedImage = [self adjustOrientationForImage:image];;
//    NSData *compressedImageData = [self jpegDataForImage:adjustedImage constraint:300];
//    
//    LYRMessagePart *part = [LYRMessagePart messagePartWithMIMEType:MIMETypeImageJPEG() data:compressedImageData];
//    LYRMessage *message = [LYRMessage messageWithConversation:self.conversation parts:@[ part ]];
//    
//    NSString *senderName = [self.persistanceManager persistedSessionWithError:nil].user.fullName;
//    NSString *pushText = [NSString stringWithFormat:@"%@: Sent you a photo!", senderName];
//    [self.layerClient setMetadata:@{LYRMessagePushNotificationAlertMessageKey: pushText} onObject:message];
//    
//    NSError *error;
//    BOOL success = [self.layerClient sendMessage:message error:&error];
//    if (success) {
//        NSLog(@"Picture Message Succesfully Sent");
//    } else {
//        NSLog(@"The error is %@", error);
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Messaging Error"
//                                                            message:[error localizedDescription]
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//        [alertView show];
//    }
//    
//}

- (UIImage *)adjustOrientationForImage:(UIImage *)originalImage
{
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, originalImage.scale);
    [originalImage drawInRect:(CGRect){0, 0, originalImage.size}];
    UIImage *fixedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return fixedImage;
}

// Photo JPEG Compression
- (NSData *)jpegDataForImage:(UIImage *)image constraint:(CGFloat)constraint
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    CGImageRef ref = [[UIImage imageWithData:imageData] CGImage];
    
    CGFloat width = 1.0f * CGImageGetWidth(ref);
    CGFloat height = 1.0f * CGImageGetHeight(ref);
    
    CGSize previousSize = CGSizeMake(width, height);
    CGSize newSize = [self sizeFromOriginalSize:previousSize withMaxConstraint:constraint];
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    UIImage *assetImage = [UIImage imageWithCGImage:ref];
    [assetImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *imageToCompress = UIGraphicsGetImageFromCurrentImageContext();
    
    return UIImageJPEGRepresentation(imageToCompress, 0.25f);
}

// Photo Resizing
- (CGSize)sizeFromOriginalSize:(CGSize)originalSize withMaxConstraint:(CGFloat)constraint
{
    if (originalSize.height > constraint && (originalSize.height > originalSize.width)) {
        CGFloat heightRatio = constraint / originalSize.height;
        return CGSizeMake(originalSize.width * heightRatio, constraint);
    } else if (originalSize.width > constraint) {
        CGFloat widthRatio = constraint / originalSize.width;
        return CGSizeMake(constraint, originalSize.height * widthRatio);
    }
    return originalSize;
}

//- (void)composeViewDidTapCamera:(LSComposeView *)composeView
//{
//    UIActionSheet *actionSheet = [[UIActionSheet alloc]
//                                  initWithTitle:nil
//                                  delegate:self
//                                  cancelButtonTitle:@"Cancel"
//                                  destructiveButtonTitle:nil
//                                  otherButtonTitles:@"Choose Existing", @"Take Photo", nil];
//    [actionSheet showInView:self.view];
//}
//
//- (void)composeView:(LSComposeView *)composeView shouldChangeHeightForLines:(double)lines
//{
//    //TODO:Implement functionality to grow text input view height to accomodate for multiple lines
//}
//
#pragma mark
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self displayImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
        case 1:
            [self displayImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
            break;
        default:
            break;
    }
}

- (void)displayImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType;
{
    BOOL camera = [UIImagePickerController isSourceTypeAvailable:sourceType];
    
    if (camera) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        
        picker.delegate = self;
        
        picker.sourceType = sourceType;
        [self.navigationController presentViewController:picker animated:YES completion:^{
            //
        }];
        NSLog(@"Camera is available");
    }
}

#pragma mark
#pragma mark Image Picker Controller Delegate

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    NSString *mediaType = [info objectForKey:@"UIImagePickerControllerMediaType"];
//    if ([mediaType isEqualToString:@"public.image"]) {
//        
//        // Get the selected image
//        UIImage *selectedImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
//        
//        //Get the rect we would like to display with a max height fo 120
//        CGRect imageRect = LSImageRectForThumb(selectedImage.size, 120);
//        
//        //Resize the compose view frame with the image
//        CGRect frame = self.composeView.frame;
//        frame.size.height = imageRect.size.height + 20;
//        frame.origin.y = self.view.frame.size.height - frame.size.height;
//        self.composeView.frame = frame;
//        
//        [self.composeView updateWithImage:selectedImage];
//    }
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark
#pragma mark Notification Observer Delegate Methods

//- (void) observerWillChangeContent:(LSNotificationObserver *)observer
//{
//    //nothing to do for now
//}
//
//- (void)observer:(LSNotificationObserver *)observer didChangeObject:(id)object atIndex:(NSUInteger)index forChangeType:(LYRObjectChangeType)changeType newIndexPath:(NSUInteger)newIndex
//{
//    //Nothing to do for now
//}
//
//- (void) observerDidChangeContent:(LSNotificationObserver *)observer
//{
//    [self fetchMessages];
//    [self.collectionView reloadData];
//    [self scrollToBottomOfCollectionViewAnimated:YES];
//}

//- (void)updateInsets
//{
//    UIEdgeInsets existing = self.collectionView.contentInset;
//    self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(existing.top, 0, self.keyboardHeight + self.composeView.frame.size.height, 0);
//}

- (CGPoint)bottomOffset
{
    return CGPointMake(0, MAX(-self.collectionView.contentInset.top, self.collectionView.collectionViewLayout.collectionViewContentSize.height - (self.collectionView.frame.size.height - self.collectionView.contentInset.bottom)));
    
}

- (void)scrollToBottomOfCollectionViewAnimated:(BOOL)animated
{
    if (self.messages.count > 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView setContentOffset:[self bottomOffset] animated:animated];
        });
    }
}


@end
