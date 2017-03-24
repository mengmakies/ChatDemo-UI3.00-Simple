/************************************************************
 *  * Hyphenate CONFIDENTIAL
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Hyphenate Inc.
 */

#import "UIViewController+SearchController.h"
#import <objc/runtime.h>

static const void *SearchControllerKey = &SearchControllerKey;
static const void *ResultControllerKey = &ResultControllerKey;

@implementation UIViewController (SearchController)

@dynamic searchController;
@dynamic resultController;

#pragma mark - getter & setter

- (UISearchController *)searchController
{
    return objc_getAssociatedObject(self, SearchControllerKey);
}

- (void)setSearchController:(UISearchController *)searchController
{
    objc_setAssociatedObject(self, SearchControllerKey, searchController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EMSearchResultController *)resultController
{
    return objc_getAssociatedObject(self, ResultControllerKey);
}

- (void)setResultController:(EMSearchResultController *)resultController
{
    objc_setAssociatedObject(self, ResultControllerKey, resultController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - enable

- (void)enableSearchController
{
    self.resultController = [[EMSearchResultController alloc] init];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.resultController];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    if ([self.searchController respondsToSelector:@selector(setObscuresBackgroundDuringPresentation:)]) {
        [self.searchController setObscuresBackgroundDuringPresentation:NO];
    }
    self.searchController.searchResultsUpdater = self;
    
    self.searchController.searchBar.delegate = self;
    self.definesPresentationContext = YES;
    
    self.searchController.searchBar.backgroundColor = [UIColor colorWithRed:0.747 green:0.756 blue:0.751 alpha:1.0];;
    
}

#pragma mark - disable

- (void)disableSearchController
{
    self.searchController.searchBar.delegate = nil;
    self.searchController = nil;
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if ([self conformsToProtocol:@protocol(EMSearchControllerDelegate)] &&
        [self respondsToSelector:@selector(willSearchBegin)]) {
        [self performSelector:@selector(willSearchBegin)];
    }
    
    return YES;
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        if ([self conformsToProtocol:@protocol(EMSearchControllerDelegate)] &&
            [self respondsToSelector:@selector(didSearchFinish)]) {
            [self performSelector:@selector(didSearchFinish)];
        }
    }
    
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if ([self conformsToProtocol:@protocol(EMSearchControllerDelegate)] &&
        [self respondsToSelector:@selector(cancelButtonClicked)]) {
        [self performSelector:@selector(cancelButtonClicked)];
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if ([self conformsToProtocol:@protocol(EMSearchControllerDelegate)]
        && [self respondsToSelector:@selector(searchTextChangeWithString:)]) {
        [self performSelector:@selector(searchTextChangeWithString:)
                   withObject:searchController.searchBar.text];
    }
}

#pragma mark - public

- (void)cancelSearch
{
    [self.searchController setActive:NO];
}

@end

