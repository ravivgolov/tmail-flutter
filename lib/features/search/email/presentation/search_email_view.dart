
import 'package:core/presentation/extensions/color_extension.dart';
import 'package:core/presentation/utils/theme_utils.dart';
import 'package:core/presentation/views/button/icon_button_web.dart';
import 'package:core/presentation/views/button/tmail_button_widget.dart';
import 'package:core/presentation/views/text/text_field_builder.dart';
import 'package:core/utils/direction_utils.dart';
import 'package:core/utils/platform_info.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:model/model.dart';
import 'package:tmail_ui_user/features/base/mixin/app_loader_mixin.dart';
import 'package:tmail_ui_user/features/base/widget/popup_menu/popup_menu_item_action_widget.dart';
import 'package:tmail_ui_user/features/base/widget/scrollbar_list_view.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/model/recent_search.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/email_receive_time_type.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/email_sort_order_type.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/search/quick_search_filter.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/widgets/quick_search/contact_quick_search_item.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/widgets/quick_search/email_quick_search_item_tile_widget.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/widgets/quick_search/recent_search_item_tile_widget.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/widgets/search_filters/search_filter_button.dart';
import 'package:tmail_ui_user/features/search/email/presentation/extension/handle_email_more_action_extension.dart';
import 'package:tmail_ui_user/features/search/email/presentation/model/context_item_receive_time_type_action.dart';
import 'package:tmail_ui_user/features/search/email/presentation/model/context_item_sort_order_type_action.dart';
import 'package:tmail_ui_user/features/search/email/presentation/model/popup_menu_item_date_filter_action.dart';
import 'package:tmail_ui_user/features/search/email/presentation/model/popup_menu_item_sort_order_type_action.dart';
import 'package:tmail_ui_user/features/search/email/presentation/model/search_more_state.dart';
import 'package:tmail_ui_user/features/search/email/presentation/search_email_controller.dart';
import 'package:tmail_ui_user/features/search/email/presentation/styles/search_email_view_style.dart';
import 'package:tmail_ui_user/features/search/email/presentation/utils/search_email_utils.dart';
import 'package:tmail_ui_user/features/search/email/presentation/widgets/app_bar_selection_mode.dart';
import 'package:tmail_ui_user/features/search/email/presentation/widgets/empty_search_email_widget.dart';
import 'package:tmail_ui_user/features/search/email/presentation/widgets/search_email_loading_bar_widget.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/features/thread/domain/state/search_more_email_state.dart';
import 'package:tmail_ui_user/features/thread/presentation/styles/item_email_tile_styles.dart';
import 'package:tmail_ui_user/features/thread/presentation/widgets/email_tile_builder.dart'
  if (dart.library.html) 'package:tmail_ui_user/features/thread/presentation/widgets/email_tile_web_builder.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';

class SearchEmailView extends GetWidget<SearchEmailController>
    with AppLoaderMixin {

  SearchEmailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.responsiveUtils.isWebDesktop(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.closeSearchView(context: context);
      });
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.white,
          child: Column(children: [
            PopScope(
              canPop: false,
              onPopInvokedWithResult: (_, __) {
                if (!PlatformInfo.isAndroid) return;
                controller.closeSearchView(context: context);
              },
              child: Container(
                  height: 52,
                  color: Colors.white,
                  padding: SearchEmailViewStyle.getAppBarPadding(
                    context,
                    controller.responsiveUtils
                  ),
                  child: Obx(() {
                    if (controller.selectionMode.value == SelectMode.ACTIVE) {
                      return AppBarSelectionMode(
                          controller.listResultSearch.listEmailSelected,
                          controller.mailboxDashBoardController.mapMailboxById,
                          onCancelSelection: controller.cancelSelectionMode,
                          onHandleEmailAction: controller.handleSelectionEmailAction);
                    } else {
                      return _buildSearchInputForm(context);
                    }
                  })
              ),
            ),
            const Divider(color: AppColor.colorDividerComposer, height: 1),
            _buildListSearchFilterAction(context),
            Obx(() => SearchEmailLoadingBarWidget(
              suggestionViewState: controller.suggestionSearchViewState.value,
              resultSearchViewState: controller.resultSearchViewState.value,
            )),
            Expanded(child: Obx(() {
              if (controller.searchIsRunning.isFalse) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(children: [
                    if (controller.currentSearchText.value.isNotEmpty)
                      _buildShowAllResultSearchButton(context, controller.currentSearchText.value),
                    if (controller.listContactSuggestionSearch.isNotEmpty
                        && controller.currentSearchText.isNotEmpty)
                      _buildListContactSuggestionSearch(context, controller.listContactSuggestionSearch),
                    if (controller.listContactSuggestionSearch.isNotEmpty
                        && controller.listSuggestionSearch.isNotEmpty)
                      const Divider(),
                    if (controller.listSuggestionSearch.isNotEmpty && controller.currentSearchText.isNotEmpty)
                      _buildListSuggestionSearch(context, controller.listSuggestionSearch)
                    else if (controller.listRecentSearch.isNotEmpty && controller.listSuggestionSearch.isEmpty)
                      _buildListRecentSearch(context, controller.listRecentSearch)
                  ]),
                );
              } else {
                if (controller.listResultSearch.isNotEmpty) {
                  return _buildListEmailBody(
                    context,
                    controller.listResultSearch
                  );
                } else {
                  return Obx(() => EmptySearchEmailWidget(
                    suggestionViewState: controller.suggestionSearchViewState.value,
                    resultSearchViewState: controller.resultSearchViewState.value,
                    isNetworkConnectionAvailable: controller.networkConnectionController.isNetworkConnectionAvailable(),
                  ));
                }
              }
            })),
            _buildLoadingViewLoadMore(),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchInputForm(BuildContext context) {
    return Row(
        children: [
          buildIconWeb(
              icon: SvgPicture.asset(
                DirectionUtils.isDirectionRTLByLanguage(context) ? controller.imagePaths.icCollapseFolder : controller.imagePaths.icBack,
                colorFilter: AppColor.colorTextButton.asFilter(),
                fit: BoxFit.fill
              ),
              tooltip: AppLocalizations.of(context).back,
              onTap: () => controller.closeSearchView(context: context)
          ),
          Expanded(child: TextFieldBuilder(
            key: const Key('search_email_text_field'),
            onTextChange: controller.onTextSearchChange,
            textInputAction: TextInputAction.search,
            controller: controller.textInputSearchController,
            focusNode: controller.textInputSearchFocus,
            maxLines: 1,
            textDirection: DirectionUtils.getDirectionByLanguage(context),
            textStyle: ThemeUtils.defaultTextStyleInterFont.copyWith(
              color: Colors.black,
              fontSize: 16,
            ),
            keyboardType: TextInputType.text,
            onTextSubmitted: (text) => controller.onTextSearchSubmitted(context, text),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              hintText: AppLocalizations.of(context).search_emails,
              hintStyle: ThemeUtils.defaultTextStyleInterFont.copyWith(
                color: AppColor.loginTextFieldHintColor,
                fontSize: 16,
              ),
              border: InputBorder.none),
          )),
          Obx(() {
            if (controller.currentSearchText.isNotEmpty) {
              return
                buildIconWeb(
                    icon: SvgPicture.asset(
                        controller.imagePaths.icClearTextSearch,
                        width: 18,
                        height: 18,
                        fit: BoxFit.fill),
                    tooltip: AppLocalizations.of(context).clearAll,
                    onTap: () => controller.clearAllTextInputSearchForm(requestFocus: true));
            } else {
              return const SizedBox.shrink();
            }
          })
        ]
    );
  }

  Widget _buildListSearchFilterAction(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            height: 45,
            margin: SearchEmailViewStyle.listSearchFilterButtonMargin,
            alignment: AlignmentDirectional.centerStart,
            child: ScrollbarListView(
              scrollBehavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad
                },
                scrollbars: false
              ),
              scrollController: controller.listSearchFilterScrollController,
              child: ListView(
                key: const Key('search_filter_list_view'),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                controller: controller.listSearchFilterScrollController,
                padding: SearchEmailViewStyle.getListSearchFilterButtonPadding(
                  context,
                  controller.responsiveUtils
                ),
                children: [
                  _buildSearchFilterButton(context, QuickSearchFilter.folder),
                  SearchEmailViewStyle.searchFilterSizeBoxMargin,
                  _buildSearchFilterButton(context, QuickSearchFilter.from),
                  SearchEmailViewStyle.searchFilterSizeBoxMargin,
                  _buildSearchFilterButton(context, QuickSearchFilter.to),
                  SearchEmailViewStyle.searchFilterSizeBoxMargin,
                  _buildSearchFilterButton(context, QuickSearchFilter.hasAttachment),
                  SearchEmailViewStyle.searchFilterSizeBoxMargin,
                  _buildSearchFilterButton(context, QuickSearchFilter.dateTime),
                  SearchEmailViewStyle.searchFilterSizeBoxMargin,
                  _buildSearchFilterButton(context, QuickSearchFilter.starred),
                  SearchEmailViewStyle.searchFilterSizeBoxMargin,
                  _buildSearchFilterButton(context, QuickSearchFilter.sortBy),
                ],
              ),
            ),
          ),
        ),
        Obx(() {
          if (controller.searchEmailFilter.value.isApplied) {
            return TMailButtonWidget.fromText(
              text: AppLocalizations.of(context).clearFilter,
              backgroundColor: Colors.transparent,
              margin: const EdgeInsetsDirectional.only(start: 8, top: 6, end: 8),
              borderRadius: 10,
              textStyle: ThemeUtils.defaultTextStyleInterFont.copyWith(
                color: AppColor.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500
              ),
              onTapActionCallback: () => controller.clearAllSearchFilterApplied(context)
            );
          } else {
            return const SizedBox.shrink();
          }
        })
      ],
    );
  }

  Widget _buildSearchFilterButton(
    BuildContext context,
    QuickSearchFilter searchFilter,
  ) {
    return Obx(() {
      final searchEmailFilter = controller.searchEmailFilter.value;
      final sortOrderType = controller.emailSortOrderType.value;
      final listAddressOfFrom = controller.listAddressOfFromFiltered;
      final currentUserEmail = controller.session?.getOwnEmailAddressOrEmpty();
      final startDate = controller.startDateFiltered;
      final endDate = controller.endDateFiltered;
      final receiveTimeType = controller.receiveTimeFiltered;
      final mailbox = controller.mailboxFiltered;
      final listAddressOfTo = controller.listAddressOfToFiltered;

      final isSelected = searchFilter.isSelected(
        context,
        searchEmailFilter,
        sortOrderType,
        currentUserEmail);

      return SearchFilterButton(
        key: Key('mobile_${searchFilter.name}_search_filter_button'),
        searchFilter: searchFilter,
        imagePaths: controller.imagePaths,
        responsiveUtils: controller.responsiveUtils,
        isSelected: isSelected,
        receiveTimeType: receiveTimeType,
        startDate: startDate,
        endDate: endDate,
        sortOrderType: sortOrderType,
        listAddressOfFrom: listAddressOfFrom,
        listAddressOfTo: listAddressOfTo,
        mailbox: mailbox,
        backgroundColor: searchFilter.getMobileBackgroundColor(isSelected: isSelected),
        onSelectSearchFilterAction: _onSelectSearchFilterAction,
        onDeleteSearchFilterAction: (searchFilter) =>
          controller.onDeleteSearchFilterAction(context, searchFilter),
      );
    });
  }

  Future<void> _onSelectSearchFilterAction(
    BuildContext context,
    QuickSearchFilter searchFilter,
    {RelativeRect? buttonPosition}
  ) async {
    switch(searchFilter) {
      case QuickSearchFilter.dateTime:
        if (buttonPosition != null) {
          _openPopupMenuDateFilter(context, buttonPosition);
        } else {
          _openContextMenuDateFilter(context);
        }
        break;
      case QuickSearchFilter.sortBy:
        if (buttonPosition != null) {
          _openPopupMenuSortFilter(context, buttonPosition);
        } else {
          _openContextMenuSortFilter(context);
        }
        break;
      case QuickSearchFilter.from:
        controller.selectContactForSearchFilter(
          context,
          PrefixEmailAddress.from);
        break;
      case QuickSearchFilter.hasAttachment:
        controller.selectHasAttachmentSearchFilter(context);
        break;
      case QuickSearchFilter.to:
        controller.selectContactForSearchFilter(
          context,
          PrefixEmailAddress.to);
        break;
      case QuickSearchFilter.folder:
        controller.selectMailboxForSearchFilter(
          context,
          controller.mailboxFiltered);
        break;
      case QuickSearchFilter.starred:
        controller.selectStarredSearchFilter(context);
        break;
      default:
        break;
    }
  }

  void _openPopupMenuDateFilter(BuildContext context, RelativeRect position) {
    final popupMenuItems = EmailReceiveTimeType.values.map((timeType) {
      return PopupMenuItem(
        padding: EdgeInsets.zero,
        child: PopupMenuItemActionWidget(
          menuAction: PopupMenuItemDateFilterAction(
            timeType,
            controller.emailReceiveTimeType.value,
            AppLocalizations.of(context),
            controller.imagePaths,
          ),
          menuActionClick: (menuAction) {
            popBack();
            controller.selectReceiveTimeQuickSearchFilter(
              context,
              menuAction.action,
            );
          },
        ),
      );
    }).toList();

    controller.openPopupMenuAction(context, position, popupMenuItems);
  }

  void _openContextMenuDateFilter(BuildContext context) {
    final contextMenuActions = EmailReceiveTimeType.values.map((timeType) {
      return ContextItemReceiveTimeTypeAction(
        timeType,
        controller.emailReceiveTimeType.value,
        AppLocalizations.of(context),
        controller.imagePaths,
      );
    }).toList();

    controller.openBottomSheetContextMenuAction(
      key: const Key('date_time_filter_context_menu'),
      context: context,
      itemActions: contextMenuActions,
      onContextMenuActionClick: (menuAction) {
        popBack();
        controller.selectReceiveTimeQuickSearchFilter(
          context,
          menuAction.action,
        );
      },
    );
  }

  void _openPopupMenuSortFilter(BuildContext context, RelativeRect position) {
    final popupMenuItems = EmailSortOrderType.values.map((sortType) {
      return PopupMenuItem(
        padding: EdgeInsets.zero,
        child: PopupMenuItemActionWidget(
          menuAction: PopupMenuItemSortOrderTypeAction(
            sortType,
            controller.emailSortOrderType.value,
            AppLocalizations.of(context),
            controller.imagePaths,
          ),
          menuActionClick: (menuAction) {
            popBack();
            controller.selectSortOrderQuickSearchFilter(
              context,
              menuAction.action,
            );
          },
        ),
      );
    }).toList();

    controller.openPopupMenuAction(context, position, popupMenuItems);
  }

  void _openContextMenuSortFilter(BuildContext context) {
    final contextMenuActions = EmailSortOrderType.values.map((orderType) {
      return ContextItemSortOrderTypeAction(
        orderType,
        controller.emailSortOrderType.value,
        AppLocalizations.of(context),
        controller.imagePaths,
      );
    }).toList();

    controller.openBottomSheetContextMenuAction(
      key: const Key('sort_filter_context_menu'),
      context: context,
      itemActions: contextMenuActions,
      onContextMenuActionClick: (menuAction) {
        popBack();
        controller.selectSortOrderQuickSearchFilter(
          context,
          menuAction.action,
        );
      },
    );
  }

  Widget _buildShowAllResultSearchButton(BuildContext context, String textSearch) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final query = textSearch.trim();
          if (query.isNotEmpty) {
            controller.saveRecentSearch(query);
            controller.showAllResultSearchAction(context, query);
          }
        },
        child: Padding(
          padding: SearchEmailViewStyle.getShowAllResultButtonPadding(
            context,
            controller.responsiveUtils
          ),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context).showingResultsFor,
                style: ThemeUtils.defaultTextStyleInterFont.copyWith(
                  fontSize: 13.0,
                  color: AppColor.colorTextButtonHeaderThread,
                  fontWeight: FontWeight.w500
                )
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '"${controller.currentSearchText.value}"',
                  style: ThemeUtils.defaultTextStyleInterFont.copyWith(
                    fontSize: 13.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w500
                  )
                )
              )
            ]
          )
        ),
      ),
    );
  }

  Widget _buildListRecentSearch(
      BuildContext context,
      List<RecentSearch> listRecentSearch
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: SearchEmailViewStyle.getSearchRecentTitleMargin(
            context,
            controller.responsiveUtils
          ),
          child: Text(
            AppLocalizations.of(context).recent,
            style: SearchEmailViewStyle.searchRecentTitleStyle
          )
        ),
        ListView.builder(
          shrinkWrap: true,
          primary: false,
          itemCount: listRecentSearch.length,
          itemBuilder: (context, index) {
            final recentSearch = listRecentSearch[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                child: RecentSearchItemTileWidget(
                  recentSearch,
                  contentPadding: SearchEmailViewStyle.getListRecentSearchPadding(
                    context,
                    controller.responsiveUtils
                  )
                ),
                onTap: () => controller.searchEmailByRecentAction(
                  context,
                  recentSearch
                ),
              ),
            );
          }
        )
      ]
    );
  }

  Widget _buildListSuggestionSearch(
      BuildContext context,
      List<PresentationEmail> listSuggestionSearch
  ) {
    return ListView.builder(
        key: const Key('suggestion_search_list_view'),
        shrinkWrap: true,
        primary: false,
        itemCount: listSuggestionSearch.length,
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              child: EmailQuickSearchItemTileWidget(
                listSuggestionSearch[index],
                controller.currentMailbox,
                searchQuery: SearchQuery(controller.currentSearchText.value.trim()),
                contentPadding: SearchEmailViewStyle.getSearchSuggestionListPadding(
                  context,
                  controller.responsiveUtils
                )
              ),
              onTap: () {
                final emailPreview = listSuggestionSearch[index];
                final mailboxContain = emailPreview
                    .findMailboxContain(controller.mailboxDashBoardController.mapMailboxById);
                controller.pressEmailAction(
                    context,
                    EmailActionType.preview,
                    emailPreview,
                    mailboxContain: mailboxContain);
              },
            ),
          );
        });
  }

  Widget _buildListContactSuggestionSearch(
    BuildContext context,
    List<EmailAddress> listContactSuggestionSearch
  ) {
    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      itemCount: listContactSuggestionSearch.length,
      itemBuilder: (context, index) {
        final emailAddress = listContactSuggestionSearch[index];
        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            child: ContactQuickSearchItem(emailAddress: emailAddress),
            onTap: () => controller.searchEmailByEmailAddressAction(
              context,
              emailAddress
            ),
          ),
        );
      }
    );
  }

  Widget _buildListEmailBody(BuildContext context, List<PresentationEmail> listPresentationEmail) {
    return NotificationListener<ScrollNotification>(
        key: const Key('search_email_list_notification_listener'),
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollEndNotification
              && controller.searchMoreState != SearchMoreState.waiting
              && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent
              && scrollInfo.metrics.axisDirection == AxisDirection.down) {
            controller.searchMoreEmailsAction();
          }
          return false;
        },
        child: PlatformInfo.isMobile
          ? ListView.separated(
              controller: controller.resultSearchScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              key: const PageStorageKey('list_presentation_email_in_search_view'),
              itemCount: listPresentationEmail.length,
              itemBuilder: (context, index) {
                final currentPresentationEmail = listPresentationEmail[index];
                return Obx(() => EmailTileBuilder(
                  presentationEmail: currentPresentationEmail,
                  selectAllMode: controller.selectionMode.value,
                  searchQuery: controller.searchQuery,
                  isShowingEmailContent: controller.mailboxDashBoardController.selectedEmail.value?.id == currentPresentationEmail.id,
                  isSenderImportantFlagEnabled: controller.mailboxDashBoardController.isSenderImportantFlagEnabled.value,
                  isSearchEmailRunning: true,
                  padding: SearchEmailViewStyle.getPaddingSearchResultList(context, controller.responsiveUtils),
                  mailboxContain: currentPresentationEmail.mailboxContain,
                  emailActionClick: (action, email) {
                    controller.pressEmailAction(
                      context,
                      action,
                      email,
                      mailboxContain: currentPresentationEmail.mailboxContain
                    );
                  },
                  onMoreActionClick: (email, position) =>
                      controller.handleEmailMoreAction(
                        context,
                        email,
                        position,
                      ),
                ));
              },
              separatorBuilder: (BuildContext context, int index) {
                if (index < listPresentationEmail.length - 1) {
                  return Padding(
                    padding: SearchEmailUtils.getPaddingItemListMobile(context, controller.responsiveUtils),
                    child: const Divider());
                } else {
                  return const SizedBox.shrink();
                }
              },
            )
          : ListView.separated(
              controller: controller.resultSearchScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              key: const PageStorageKey('list_presentation_email_in_search_view'),
              itemCount: listPresentationEmail.length,
              itemBuilder: (context, index) {
                final currentPresentationEmail = listPresentationEmail[index];
                return Obx(() => EmailTileBuilder(
                  presentationEmail: currentPresentationEmail,
                  selectAllMode: controller.selectionMode.value,
                  searchQuery: controller.searchQuery,
                  isShowingEmailContent: controller.mailboxDashBoardController.selectedEmail.value?.id == currentPresentationEmail.id,
                  isSenderImportantFlagEnabled: controller.mailboxDashBoardController.isSenderImportantFlagEnabled.value,
                  isSearchEmailRunning: true,
                  padding: SearchEmailViewStyle.getPaddingSearchResultList(
                    context,
                    controller.responsiveUtils
                  ),
                  mailboxContain: currentPresentationEmail.mailboxContain,
                  emailActionClick: (action, email) {
                    controller.pressEmailAction(
                      context,
                      action,
                      email,
                      mailboxContain: currentPresentationEmail.mailboxContain
                    );
                  },
                  onMoreActionClick: (email, position) =>
                      controller.handleEmailMoreAction(
                        context,
                        email,
                        position,
                      ),
                ));
              },
              separatorBuilder: (context, index) {
                return Padding(
                  padding: ItemEmailTileStyles.getPaddingDividerWeb(context, controller.responsiveUtils),
                  child: Divider(
                    color: index < listPresentationEmail.length - 1 &&
                      controller.selectionMode.value == SelectMode.INACTIVE
                      ? null
                      : Colors.white
                  )
                );
              },
            )
    );
  }

  Widget _buildLoadingViewLoadMore() {
    return Obx(() => controller.viewState.value.fold(
        (failure) => const SizedBox.shrink(),
        (success) {
          return success is SearchingMoreState
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: loadingWidget)
              : const SizedBox.shrink();
        }));
  }
}