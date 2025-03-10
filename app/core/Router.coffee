dynamicRequire = require('lib/dynamicRequire')
locale = require 'locale/locale'
globalVar = require 'core/globalVar'

go = (path, options) -> -> @routeDirectly path, arguments, options

# This can be wrapped around existing route functions,
# to restrict the new teacher dashboard only for admins (using flag newTeacherDashboardActive)
teacherProxyRoute = (originalRoute) -> ->
  # if sessionStorage.getItem('newTeacherDashboardActive') == 'active'
  return go('core/SingletonAppVueComponentView').apply(@, arguments)
  # originalRoute.apply(@, arguments)

redirect = (path) -> ->
  delete window.alreadyLoadedView
  @navigate(path + document.location.search, { trigger: true, replace: true })

utils = require './utils'
ViewLoadTimer = require 'core/ViewLoadTimer'
paymentUtils = require 'lib/paymentUtils'

module.exports = class CocoRouter extends Backbone.Router

  _routeToRegExp: (route) ->
    new RegExp(super(route), 'i') # make all routes case insensitive

  initialize: ->
    # http://nerds.airbnb.com/how-to-add-google-analytics-page-tracking-to-57536
    @bind 'route', @_trackPageView
    Backbone.Mediator.subscribe 'router:navigate', @onNavigate, @
    @initializeSocialMediaServices = _.once @initializeSocialMediaServices

    # Lazily require and load VueRouter because it currently loads all of its dependencies
    # in a single Webpack bundle.  The app initialization logic assumes that all Views are
    # loaded lazily and thus will not be initialized as part of the initial page load.
    #
    # Because Vue router and its dependencies are loaded in a single bundle any CocoViews
    # that are loaded via the Vue router are initialized too early.  Delaying loading of
    # Vue router delays initialization of dependent CocoViews until an appropriate time.
    #
    # TODO Integrate webpack bundle loading with vueRouter and load this normally
    @vueRouter = require('app/core/vueRouter').default()

  routes:
    '': ->
      if window.serverConfig.picoCTF
        return @routeDirectly 'play/CampaignView', ['picoctf'], {}
      if utils.getQueryVariable 'hour_of_code'
        delete window.alreadyLoadedView
        return @navigate "/play?hour_of_code=true", {trigger: true, replace: true}

      if utils.isCodeCombat
        if utils.getQueryVariable 'payment-homeSubscriptions'
          return @routeDirectly 'HomeView'
        unless me.isAnonymous() or me.isStudent() or me.isTeacher() or me.isAdmin() or me.hasSubscription() or me.isAPIClient() or paymentUtils.hasTemporaryPremiumAccess() or me.isParentHome()
          delete window.alreadyLoadedView
          return @navigate "/premium", {trigger: true, replace: true}
        if me.isAPIClient()
          delete window.alreadyLoadedView
          #return @navigate "/league/#{me.get('clans')?[0] ? ''}apiclient-data", {trigger: true, replace: true}  # Once we make sure all students have been associated with their API creators
          return @navigate "/partner-dashboard", {trigger: true, replace: true}
        if me.useChinaHomeView()
          delete window.alreadyLoadedView
          return @routeDirectly('HomeCNView', [])
      return @routeDirectly('HomeView', [])

    'about': go('AboutView')
    'contact-cn': go('ContactCNView')
    'china-bridge': go('ChinaBridgeView')

    'account': go('account/MainAccountView')
    'account/oauth-aiyouth': go('account/OAuthAIYouthView')

    'account/settings': go('account/AccountSettingsRootView')
    'account/unsubscribe': go('account/UnsubscribeView')
    'account/payments': go('account/PaymentsView')
    'account/subscription': go('account/SubscriptionView', { redirectStudents: true, redirectTeachers: true })
    'account/invoices': go('account/InvoicesView')
    'account/prepaid': go('account/PrepaidView')

    'ai': go('ai/AIView')
    'ai/*path': go('ai/AIView')

    'licensor': go('LicensorView')

    'admin': go('admin/MainAdminView')
    'admin/clas': go('admin/CLAsView')
    'admin/classroom-content': go('admin/AdminClassroomContentView')
    'admin/classroom-levels': go('admin/AdminClassroomLevelsView')
    'admin/partial-unit-release': () ->
      @routeDirectly('views/admin/PartialUnitReleaseView', [], { vueRoute: true, baseTemplate: 'base-empty' })
    'admin/classrooms-progress': go('admin/AdminClassroomsProgressView')
    'admin/design-elements': go('admin/DesignElementsView')
    'admin/files': go('admin/FilesView')
    'admin/analytics': go('admin/AnalyticsView')
    'admin/analytics/subscriptions': go('admin/AnalyticsSubscriptionsView')
    'admin/level-hints': go('admin/AdminLevelHintsView')
    'admin/level-sessions': go('admin/LevelSessionsView')
    'admin/school-counts': go('admin/SchoolCountsView')
    'admin/school-licenses': go('admin/SchoolLicensesView')
    'admin/sub-cancellations': go('admin/AdminSubCancellationsView')
    'admin/base': go('admin/BaseView')
    'admin/demo-requests': go('admin/DemoRequestsView')
    'admin/trial-requests': go('admin/TrialRequestsView')
    'admin/user-code-problems': go('admin/UserCodeProblemsView')
    'admin/pending-patches': go('admin/PendingPatchesView')
    'admin/codelogs': go('admin/CodeLogsView')
    'admin/skipped-contacts': go('admin/SkippedContactsView')
    'admin/outcomes-report-result': go('admin/OutcomeReportResultView')
    'admin/outcomes-report': go('admin/OutcomesReportView')
    'admin/clan(/:clanID)': go('core/SingletonAppVueComponentView')

    'announcements': go('core/SingletonAppVueComponentView')
    'event-calendar(/*subpath)': go('core/SingletonAppVueComponentView')

#    'apcsp(/*subpath)': go('teachers/DynamicAPCSPView')

    'library-dashboard': go('core/SingletonAppVueComponentView')
    'partner-dashboard': go('core/SingletonAppVueComponentView')
    'api-dashboard': go('core/SingletonAppVueComponentView')

    'artisans': go('artisans/ArtisansView')

    'artisans/level-tasks': go('artisans/LevelTasksView')
    'artisans/solution-problems': go('artisans/SolutionProblemsView')
    'artisans/thang-tasks': go('artisans/ThangTasksView')
    'artisans/level-concepts': go('artisans/LevelConceptMap')
    'artisans/level-guides': go('artisans/LevelGuidesView')
    'artisans/student-solutions': go('artisans/StudentSolutionsView')
    'artisans/sandbox': go('artisans/SandboxView')
    'artisans/arena-balancer(/:levelSlug)': go('artisans/ArenaBalancerView')

    'careers': => window.location.href = 'https://jobs.lever.co/codecombat'

    'cla': go('CLAView')

    'clans': go('clans/ClansView', { redirectStudents: true })
    'clans/:clanID': go('clans/ClanDetailsView', { redirectStudents: true })

    'community': -> @navigate "/contribute", {trigger: true, replace: true}

    'contribute': go('contribute/MainContributeView')
    'contribute/adventurer': go('contribute/AdventurerView')
    'contribute/ambassador': go('contribute/AmbassadorView')
    'contribute/archmage': go('contribute/ArchmageView')
    'contribute/artisan': go('contribute/ArtisanView')
    'contribute/diplomat': go('contribute/DiplomatView')
    'contribute/scribe': go('contribute/ScribeView')

    'courses': redirect('/students') # Redirected 9/3/16
    'Courses': redirect('/students') # Redirected 9/3/16
    'courses/students': redirect('/students') # Redirected 9/3/16
    'courses/teachers': redirect('/teachers/classes')
    'courses/purchase': redirect('/teachers/licenses')
    'courses/enroll(/:courseID)': redirect('/teachers/licenses')
    'courses/update-account': redirect('students/update-account') # Redirected 9/3/16
    'courses/:classroomID': -> @navigate("/students/#{arguments[0]}", {trigger: true, replace: true}) # Redirected 9/3/16
    'courses/:courseID/:courseInstanceID': -> @navigate("/students/#{arguments[0]}/#{arguments[1]}", {trigger: true, replace: true}) # Redirected 9/3/16

    'dei': go('core/SingletonAppVueComponentView')
    'diversity-equity-and-inclusion': go('core/SingletonAppVueComponentView')
    'db/*path': 'routeToServer'
    'docs/components': go('editor/docs/ComponentsDocumentationView')
    'docs/systems': go('editor/docs/SystemsDocumentationView')

    'editor': go('CommunityView')

    'editor/concept': go('editor/concept/ConceptSearchView')
    'editor/concept/:conceptID': go('editor/concept/ConceptEditView')
    'editor/standards': go('editor/standards/StandardsSearchView')
    'editor/standards/:standardsID': go('editor/standards/StandardsEditView')
    'editor/achievement': go('editor/achievement/AchievementSearchView')
    'editor/achievement/:articleID': go('editor/achievement/AchievementEditView')
    'editor/article': go('editor/article/ArticleSearchView')
    'editor/article/preview': go('editor/article/ArticlePreviewView')
    'editor/article/:articleID': go('editor/article/ArticleEditView')
    'editor/announcement': go('editor/announcement/AnnouncementSearchView')
    'editor/announcement/:announcementId': go('editor/announcement/AnnouncementEditView')
    'editor/cinematic(/*subpath)': go('core/SingletonAppVueComponentView')
    'editor/cutscene(/*subpath)': go('core/SingletonAppVueComponentView')
    'editor/interactive(/*subpath)': go('core/SingletonAppVueComponentView')
    'editor/level': go('editor/level/LevelSearchView')
    'editor/level/:levelID': go('editor/level/LevelEditView')
    'editor/thang': go('editor/thang/ThangTypeSearchView')
    'editor/thang/:thangID': go('editor/thang/ThangTypeEditView')
    'editor/campaign/:campaignID(/:campaignPage)': go('editor/campaign/CampaignEditorView')
    'editor/poll': go('editor/poll/PollSearchView')
    'editor/poll/:articleID': go('editor/poll/PollEditView')
    'editor/verifier(/:levelID)': go('editor/verifier/VerifierView')
    'editor/i18n-verifier(/:levelID)': go('editor/verifier/i18nVerifierView')
    'editor/course': go('editor/course/CourseSearchView')
    'editor/course/:courseID': go('editor/course/CourseEditView')
    'editor/resource': go('editor/resource/ResourceSearchView')
    'editor/resource/:resourceID': go('editor/resource/ResourceEditView')
    'editor/archived-elements': go('core/SingletonAppVueComponentView')
    'editor/podcast': go('editor/podcast/PodcastSearchView')
    'editor/podcast/:podcastId': go('editor/podcast/PodcastEditView')
    'editor/chat': go('editor/chat/ChatSearchView')
    'editor/chat/:chatID': go('editor/chat/ChatEditView')
    'editor/ai-scenario': go('editor/ai-scenario/AIScenarioSearchView')
    'editor/ai-scenario/:chatID': go('editor/ai-scenario/AIScenarioEditView')
    'editor/ai-project': go('editor/ai-project/AIProjectSearchView')
    'editor/ai-project/:chatID': go('editor/ai-project/AIProjectEditView')
    'editor/ai-model': go('editor/ai-model/AIModelSearchView')
    'editor/ai-model/:modelID': go('editor/ai-model/AIModelEditView')
    'editor/ai-document': go('editor/ai-document/AIDocumentSearchView')
    'editor/ai-document/:documentID': go('editor/ai-document/AIDocumentEditView')
    'editor/ai-chat-message': go('editor/ai-chat-message/AIChatMessageSearchView')
    'editor/ai-chat-message/:chatMessageID': go('editor/ai-chat-message/AIChatMessageEditView')


    'etc': redirect('/teachers/demo')
    'demo': redirect('/teachers/demo')
    'quote': redirect('/teachers/demo')

    'file/*path': 'routeToServer'

    'funding': go('core/SingletonAppVueComponentView')

    'github/*path': 'routeToServer'

    'hoc': (queryString) ->
       if utils.isCodeCombat
         @navigate "/play/hoc-2018", {trigger: true, replace: true}
       else
        queryString ?= ''
        # Load the tracking image without it disrupting the page layout.
        hocImg = new Image()
        hocImg.src = 'https://code.org/api/hour/begin_codecombat_ozaria.png'
        if queryString
          queryString = '&' + queryString
        @navigate("/play/chapter-1-sky-mountain?hour_of_code=true#{queryString}", { trigger: true })

    'play/hoc-2020': -> @navigate "/play/hoc-2018", {trigger: true, replace: true} # Added to handle HoC PDF
    'home': if utils.isCodeCombat and me.useChinaHomeView() then go('HomeCNView') else go('HomeView')

    'i18n': go('i18n/I18NHomeView')
    'i18n/thang/:handle': go('i18n/I18NEditThangTypeView')
    'i18n/component/:handle': go('i18n/I18NEditComponentView')
    'i18n/level/:handle': go('i18n/I18NEditLevelView')
    'i18n/achievement/:handle': go('i18n/I18NEditAchievementView')
    'i18n/campaign/:handle': go('i18n/I18NEditCampaignView')
    'i18n/poll/:handle': go('i18n/I18NEditPollView')
    'i18n/course/:handle': go('i18n/I18NEditCourseView')
    'i18n/cinematic/:handle': go('i18n/I18NEditCinematicView')
    'i18n/product/:handle': go('i18n/I18NEditProductView')
    'i18n/article/:handle': go('i18n/I18NEditArticleView')
    'i18n/interactive/:handle': go('i18n/I18NEditInteractiveView')
    'i18n/cutscene/:handle': go('i18n/I18NEditCutsceneView')
    'i18n/resource_hub_resource/:handle': go('i18n/I18NEditResourceHubResourceView')
    'i18n/concept/:handle': go('i18n/I18NEditConceptView')
    'i18n/standards/:handle': go('i18n/I18NEditStandardsCorrelationView')
    'i18n/ai/scenario/:handle': go('i18n/I18NEditAIScenarioView')
    'i18n/ai/chat_message/:handle': go('i18n/I18NEditAIChatMessageView')
    'i18n/ai/document/:handle': go('i18n/I18NEditAIDocumentView')


    'identify': go('user/IdentifyView')
    'il-signup': go('account/IsraelSignupView')

    'impact': () ->
      @routeDirectly('PageImpact', [], { vueRoute: true, baseTemplate: 'base-flat-vue' })

    'partners': () ->
      @routeDirectly('PagePartners', [], { vueRoute: true, baseTemplate: 'base-flat-vue' })

    'apcsp': () ->
      @routeDirectly('PageAPCSPMarketing', [], { vueRoute: true, baseTemplate: 'base-flat-vue' })

    'apcspportal': () ->
      @routeDirectly('PageAPCSPCurriculum', [], { vueRoute: true, baseTemplate: 'base-flat-vue' })

    'apcsportal': () ->
      @routeDirectly('PageAPCSPCurriculum', [], { vueRoute: true, baseTemplate: 'base-flat-vue' })

    'league/academica': redirect('/league/autoclan-school-network-academica') # Redirect for Academica.
    'league/kipp': redirect('/league/autoclan-school-network-kipp') # Redirect for KIPP.
    'league(/*subpath)': go('core/SingletonAppVueComponentView')

    'legal': go('LegalView')

    'logout': 'logout'

    'minigames/conditionals': go('minigames/ConditionalMinigameView')

    'mobile': () ->
      @routeDirectly('views/landing-pages/mobile/PageMobileView', [], { vueRoute: true, baseTemplate: 'base-empty' })

    'parents': go('core/SingletonAppVueComponentView')
    'parents/*path': go('core/SingletonAppVueComponentView')
    'live-classes': go('core/SingletonAppVueComponentView')
    'live': go('core/SingletonAppVueComponentView')

    'outcomes-report(/*subpath)': go('core/SingletonAppVueComponentView')

    # Warning: In production debugging of third party iframe!
    'temporary-debug-timetap': go('core/SingletonAppVueComponentView')

    'paypal/subscribe-callback': go('play/CampaignView')
    'paypal/cancel-callback': go('account/SubscriptionView')

    'tournaments/:pageType/:objectId': go('ladder/MainTournamentView')

    'play(/)': go('play/CampaignView', { redirectStudents: true, redirectTeachers: true }) # extra slash is to get Facebook app to work
    'play/ladder/:levelID/:leagueType/:leagueID': go('ladder/LadderView')
    'play/ladder/:levelID': go('ladder/LadderView')
    'play/ladder': go('ladder/MainLadderView')
    'play/level/:levelID': (levelID, options) ->
      if utils.isCodeCombat
        @routeDirectly('play/level/PlayLevelView', arguments, options)
      else
        props = {
          levelID: levelID
        }
        @routeDirectly('ozaria/site/play/PagePlayLevel', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props})
    'play/intro/:introLevelIdOrSlug': (introLevelIdOrSlug) ->
      props = {
        introLevelIdOrSlug: introLevelIdOrSlug
      }
      @routeDirectly('introLevel', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props})

    'play/video/level/:levelID': go('play/level/PlayLevelVideoView')
    'play/game-dev-level/:sessionID': go('play/level/PlayGameDevLevelView')
    'play/web-dev-level/:sessionID': go('play/level/PlayWebDevLevelView')
    'play/game-dev-level/:levelID/:sessionID': (levelID, sessionID, queryString) ->
      @navigate("play/game-dev-level/#{sessionID}?#{queryString}", { trigger: true, replace: true })
    'play/web-dev-level/:levelID/:sessionID': (levelID, sessionID, queryString) ->
      @navigate("play/web-dev-level/#{sessionID}?#{queryString}", { trigger: true, replace: true })
    'play/spectate/:levelID': go('play/SpectateView')
    'play/:campaign': (campaign) ->
      if utils.isCodeCombat
        @routeDirectly('play/CampaignView', arguments)
      else
       props = {
         campaign: campaign
       }
       @routeDirectly('ozaria/site/play/PageUnitMap', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props})
    # These are admin-only routes since they are only used internally for testing -> interactive/, cinematic/, cutscene/, ozaria/avatar-selector
    'interactive/:interactiveIdOrSlug(?code-language=:codeLanguage)': (interactiveIdOrSlug, codeLanguage) ->
      props = {
        interactiveIdOrSlug: interactiveIdOrSlug,
        codeLanguage: codeLanguage # This will also come from intro level page later
      }
      @routeDirectly('interactive', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props}) if me.isAdmin()

    'cinematic/:cinematicIdOrSlug': (cinematicIdOrSlug) ->
      props = {
        cinematicIdOrSlug: cinematicIdOrSlug,
      }
      @routeDirectly('cinematic', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props}) if me.isAdmin()

    'cutscene/:cutsceneId': (cutsceneId) ->
      props = {
        cutsceneId: cutsceneId,
      }
      @routeDirectly('cutscene', [], { vueRoute: true, baseTemplate: 'base-empty', propsData: props }) if me.isAdmin()

    'premium': go('PremiumFeaturesView', { redirectStudents: true, redirectTeachers: true })

    'ozaria/avatar-selector': () ->
      @routeDirectly('ozaria/site/avatarSelector', [], { vueRoute: true, baseTemplate: 'base-empty' }) if me.isAdmin()

    'preview': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')

    'privacy': go('PrivacyView')

    'professional-development': go('core/SingletonAppVueComponentView')
    'pd': go('core/SingletonAppVueComponentView')
    'efficacy': go('core/SingletonAppVueComponentView')

    'sel': go('core/SingletonAppVueComponentView')
    'social-and-emotional-learning': go('core/SingletonAppVueComponentView')

    'roblox': go('core/SingletonAppVueComponentView')
    'grants': go('core/SingletonAppVueComponentView')

    'schools': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')
    'seen': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')

    'students': go('courses/CoursesView', { redirectTeachers: true })
    'students/update-account': go('courses/CoursesUpdateAccountView', { redirectTeachers: true })
    'students/project-gallery/:courseInstanceID': go('courses/ProjectGalleryView')
    'students/assessments/:classroomID': go('courses/StudentAssessmentsView')
    'students/videos/:courseID/:courseName': go('courses/CourseVideosView')
    'students/:classroomID': go('courses/ClassroomView', { redirectTeachers: true, studentsOnly: true })
    'students/:courseID/:courseInstanceID': go('courses/CourseDetailsView', { redirectTeachers: true, studentsOnly: true })

    'teachers': ->
      if utils.isCodeCombat
        delete window.alreadyLoadedView
        @navigate('/teachers/classes' + document.location.search, { trigger: true, replace: true })
      else
        @routeDirectly('core/SingletonAppVueComponentView', arguments, {redirectStudents: true, teachersOnly: true})
    'teachers/classes': ->
      if utils.isCodeCombat
        @routeDirectly('courses/TeacherClassesView', [], { redirectStudents: true, teachersOnly: true })
      else
        @routeDirectly('core/SingletonAppVueComponentView', arguments, {redirectStudents: true, teachersOnly: true})
    'teachers/projects/:classroomId': go('core/SingletonAppVueComponentView')
    'teachers/classes/:classroomID/:studentID': go('teachers/TeacherStudentView', { redirectStudents: true, teachersOnly: true })
    'teachers/classes/:classroomID': ->
      if utils.isCodeCombat
        @routeDirectly('courses/TeacherClassView', arguments, { redirectStudents: true, teachersOnly: true })
      else
        @routeDirectly('core/SingletonAppVueComponentView', arguments, {redirectStudents: true, teachersOnly: true})
    'teachers/courses': ->
      if utils.isCodeCombat
        @routeDirectly('courses/TeacherCoursesView', arguments, { redirectStudents: true })
      else
        delete window.alreadyLoadedView
        @navigate('/teachers'+document.location.search, { trigger: true, replace: true })
    'teachers/units': redirect('/teachers') # Redirected 9/10/2020
    'teachers/course-solution/:courseID/:language': go('teachers/TeacherCourseSolutionView', { redirectStudents: true })
    'teachers/campaign-solution/:courseID/:language': go('teachers/TeacherCourseSolutionView', { redirectStudents: true, campaignMode: true })
    'teachers/demo': redirect('/teachers/quote')
    'teachers/enrollments': redirect('/teachers/licenses')
    'teachers/hour-of-code': ->
      if utils.isCodeCombat
        @routeDirectly('special_event/HoC2018View', [], {})
      else
        window.location.href = 'https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing'
    # Redundant linking in case of external linking to our hoc resources:
    'teachers/resources/hoc2019':  => window.location.href = 'https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing'
    'teachers/resources/hoc2020':  => window.location.href = 'https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing'
    'teachers/licenses/v0': go('courses/EnrollmentsView', { redirectStudents: true, teachersOnly: true })

    'teachers/freetrial': go('teachers/RequestQuoteView', { redirectStudents: true })
    'teachers/quote': go('teachers/RequestQuoteView', { redirectStudents: true })
    'teachers/resources_old': go('teachers/ResourceHubView', { redirectStudents: true })
    'teachers/resources': if utils.isCodeCombat and me.useChinaHomeView() then go('teachers/ResourceHubView', { redirectStudents: true }) else go('core/SingletonAppVueComponentView', { redirectStudents: true })
    'teachers/resources_new': go('core/SingletonAppVueComponentView')
    'teachers/resources/ap-cs-principles': go('teachers/ApCsPrinciplesView', { redirectStudents: true })
    'teachers/resources/:name': go('teachers/MarkdownResourceView', { redirectStudents: true })
    'teachers/professional-development': teacherProxyRoute(go('pd/PDView', { redirectStudents: true }))
    'teachers/signup': ->
      return @routeDirectly('teachers/CreateTeacherAccountView', []) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @navigate('/teachers/update-account', {trigger: true, replace: true})
    'teachers/update-account': ->
      return @navigate('/teachers/signup', {trigger: true, replace: true}) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @routeDirectly('teachers/ConvertToTeacherAccountView', [])

    'school-administrator(/*subpath)': go('core/SingletonAppVueComponentView')
    'cinematicplaceholder/:levelSlug': go('core/SingletonAppVueComponentView')

    'sign-up/educator': go('core/SingletonAppVueComponentView')

    'test(/*subpath)': go('TestView')

    'user/:slugOrID': go('user/MainUserView')
    'certificates/:slugOrID': go('user/CertificatesView')
    'certificates/all-courses/:slugOrID': go('user/AllCoursesCertificatesView')
    'certificates/:id/anon': go('user/AnonCertificatesView')

    'user/:userID/verify/:verificationCode': go('user/EmailVerifiedView')
    'user/:userID/opt-in/:verificationCode': go('user/UserOptInView')

    'users/switch-account': go('core/SingletonAppVueComponentView')
    'users/switch-account/*path': go('core/SingletonAppVueComponentView')

    'payments/*path': go('core/SingletonAppVueComponentView')
    'ladders/*path': go('core/SingletonAppVueComponentView')
    'ed-link/*path': go('core/SingletonAppVueComponentView')
    'teachers/licenses': go('core/SingletonAppVueComponentView')
    'teachers/licenses/join': go('core/SingletonAppVueComponentView')
    'podcast': go('core/SingletonAppVueComponentView')
    'podcast/*path': go('core/SingletonAppVueComponentView')

    'libraries': go('core/SingletonAppVueComponentView')
    'library/*path': go('core/SingletonAppVueComponentView')

    'acte': redirect('/home?registering=true&referrerEvent=ACTE#create-account-teacher')

    '*name/': 'removeTrailingSlash'
    '*name': go('NotFoundView')

  routeToServer: (e) ->
    window.location.href = window.location.href

  removeTrailingSlash: (e) ->
    @navigate e, {trigger: true}

  routeDirectly: (path, args=[], options={}) ->
    @vueRouter.push("/#{Backbone.history.getFragment()}").catch (e) ->
      console.error 'vue router push warning:', e

    if window.alreadyLoadedView
      path = window.alreadyLoadedView

    @viewLoad = new ViewLoadTimer() unless options.recursive
    if options.redirectStudents and me.isStudent() and not me.isAdmin()
      return @redirectHome()
    if options.redirectTeachers and me.isTeacher() and not me.isAdmin()
      return @redirectHome()
    if options.teachersOnly and not (me.isTeacher() or me.isAdmin())
      return @routeDirectly('teachers/RestrictedToTeachersView')
    if options.studentsOnly and not (me.isStudent() or me.isAdmin())
      return @routeDirectly('courses/RestrictedToStudentsView')
    leavingMessage = _.result(globalVar.currentView, 'onLeaveMessage')
    if leavingMessage
      # Custom messages don't work any more, main browsers just show generic ones. So, this could be refactored.
      if not confirm(leavingMessage)
        return @navigate(this.path, {replace: true})
      else
        globalVar.currentView.onLeaveMessage = _.noop # to stop repeat confirm calls

    # TODO: Combine these two?
    if features.playViewsOnly and not (_.string.startsWith(document.location.pathname, '/play') or document.location.pathname is '/admin')
      delete window.alreadyLoadedView
      return @navigate('/play', { trigger: true, replace: true })
    if features.playOnly and not /^(views)?\/?play/.test(path)
      delete window.alreadyLoadedView
      path = 'play/CampaignView'

    path = "views/#{path}" if not _.string.startsWith(path, 'views/')
    Promise.all([
      dynamicRequire[path](), # Load the view file
      # The locale load is already initialized by `application`, just need the promise
      locale.load(me.get('preferredLanguage', true))
    ]).then ([ViewClass]) =>
      return go('NotFoundView') if not ViewClass

      # send url info to teachers
      if utils.useWebsocket && me.isStudent()
        wsBus = globalVar.application.wsBus
        Object.entries(wsBus.wsInfos?.friends ? {}).forEach(([to, friend]) =>
          return unless friend.role == 'teacher' and friend.online
          routeInfo =
            to: to,
            type: 'send',
            infos: { viewName: ViewClass.default.name, url: window.location.href }
          wsBus.ws.sendJSON(routeInfo)
        )

      SingletonAppVueComponentView = require('views/core/SingletonAppVueComponentView').default
      if ViewClass == SingletonAppVueComponentView && globalVar.currentView instanceof SingletonAppVueComponentView
        # The SingletonAppVueComponentView maintains its own Vue app with its own routing layer.  If it
        # is already routed we do not need to route again
        console.debug("Skipping route in Backbone - delegating to Vue app")
        return
      else if options.vueRoute  # Routing to a vue component using VueComponentView
        vueComponentView = require 'views/core/VueComponentView'
        view = new vueComponentView(ViewClass.default, options, args...)
      else
        Klass = if ViewClass.default then ViewClass.default else ViewClass
        view = new Klass(options, args...)  # options, then any path fragment args

      view.render()

      if window.alreadyLoadedView
        console.log "Need to merge view"
        delete window.alreadyLoadedView
        @mergeView(view)
      else
        @openView(view)

      @viewLoad.setView(view)
      @viewLoad.record()
    .catch (err) ->
      console.log err

  redirectHome: ->
    delete window.alreadyLoadedView
    homeUrl = switch
      #when me.isAPIClient() then "/league/#{me.get('clans')?[0] ? ''}#apiclient-data"  # Once we make sure all students have been associated with their API creators
      when me.isAPIClient() then "/partner-dashboard"
      when me.isStudent() then '/students'
      when me.isTeacher() then '/teachers'
      else '/'
    @navigate(homeUrl, {trigger: true, replace: true})

  openView: (view) ->
    @closeCurrentView()
    $('#page-container').empty().append view.el
    @activateTab()
    @didOpenView view

  mergeView: (view) ->
    unless view.mergeWithPrerendered?
      return @openView(view)

    target = $('#page-container>div')
    view.mergeWithPrerendered target
    view.setElement target[0]
    @didOpenView view

  didOpenView: (view) ->
    globalVar.currentView = view
    view.afterInsert()
    view.didReappear()
    @path = document.location.pathname + document.location.search
    @trigger 'did-load-route'

  closeCurrentView: ->
    if globalVar.currentView?.reloadOnClose
      return document.location.reload()
    currentModal?.hide?()
    return unless globalVar.currentView?
    globalVar.currentView.modalClosed()
    globalVar.currentView.destroy()
    $('.popover').popover 'hide'
    $('#flying-focus').css({top: 0, left: 0}) # otherwise it might make the page unnecessarily tall
    _.delay (->
      $('html')[0].scrollTop = 0
      $('body')[0].scrollTop = 0
    ), 10

  initializeSocialMediaServices: ->
    return if application.testing or application.demoing or not me.useSocialSignOn()
    application.facebookHandler.loadAPI()
    application.gplusHandler.loadAPI()
    require('core/services/twitter')()

  activateTab: ->
    base = _.string.words(document.location.pathname[1..], '/')[0]
    try
      $("ul.nav li.#{base}").addClass('active')
    catch e
      console.warn e  # Possibly a hash that would not match a valid element

  _trackPageView: ->
    window.tracker?.trackPageView()

  onNavigate: (e, recursive=false) ->
    @viewLoad = new ViewLoadTimer() unless recursive
    if _.isString e.viewClass
      dynamicRequire[e.viewClass]().then (viewClass) =>
        @onNavigate(_.assign({}, e, {viewClass}), true)
      return

    manualView = e.view or e.viewClass
    if (e.route is document.location.pathname) and not manualView
      return document.location.reload()
    @navigate e.route, {trigger: not manualView}
    @_trackPageView()
    return unless manualView
    if e.viewClass
      args = e.viewArgs or []
      Klass = if e.viewClass.default then e.viewClass.default else e.viewClass
      view = new Klass(args...)
      view.render()
      @openView view
      @viewLoad.setView(view)
    else
      @openView e.view
      @viewLoad.setView(e.view)
    @viewLoad.record()

  navigate: (fragment, options) ->
    super fragment, options
    Backbone.Mediator.publish 'router:navigated', route: fragment

  reload: ->
    document.location.reload()

  logout: ->
    me.logout()
    @navigate('/', { trigger: true })
