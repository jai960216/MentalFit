import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core
import '../../core/config/app_colors.dart';

// Shared
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/theme_aware_widgets.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: const CustomAppBar(title: '개인정보처리방침'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: ThemedContainer(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === 헤더 ===
                  _buildHeader(),

                  SizedBox(height: 24.h),

                  // === 목차 ===
                  _buildTableOfContents(),

                  SizedBox(height: 32.h),

                  // === 내용 ===
                  _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 24.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8.w),
            const ThemedText(
              text: '개인정보처리방침',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        const ThemedText(
          text: '시행일자: 2024년 1월 1일',
          isPrimary: false,
          style: TextStyle(fontSize: 12.0),
        ),
        SizedBox(height: 4.h),
        const ThemedText(
          text: '최종 개정일: 2024년 12월 1일',
          isPrimary: false,
          style: TextStyle(fontSize: 12.0),
        ),
      ],
    );
  }

  Widget _buildTableOfContents() {
    final contents = [
      '1. 개인정보의 처리목적',
      '2. 개인정보의 처리 및 보유기간',
      '3. 개인정보의 제3자 제공',
      '4. 개인정보처리의 위탁',
      '5. 정보주체의 권리·의무 및 행사방법',
      '6. 개인정보의 파기',
      '7. 개인정보 보호책임자',
      '8. 개인정보 처리방침의 변경',
    ];

    return ThemedContainer(
      useSurface: false, // background color
      addShadow: false,
      padding: EdgeInsets.all(16.w),
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThemedText(
            text: '목차',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          ...contents.map(
            (content) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: ThemedText(
                text: content,
                isPrimary: false,
                style: const TextStyle(fontSize: 14.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: '1. 개인정보의 처리목적',
          content: '''멘탈핏(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다:

• 회원 가입 및 관리
  - 회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증
  - 회원자격 유지·관리, 서비스 부정이용 방지, 각종 고지·통지

• 서비스 제공 및 계약의 이행
  - AI 상담 서비스 제공, 전문 상담사 매칭 서비스
  - 자가진단 및 심리검사 서비스, 상담 예약 및 관리
  - 맞춤형 서비스 제공, 서비스 이용기록과 접속빈도 분석

• 고객 상담 및 민원 처리
  - 민원인의 신원 확인, 민원사항 확인, 사실조사를 위한 연락·통지
  - 처리결과 통보

• 마케팅 및 광고에의 활용
  - 이벤트 및 광고성 정보 제공 및 참여기회 제공
  - 인구통계학적 특성에 따른 서비스 제공 및 광고 게재''',
        ),

        _buildSection(
          title: '2. 개인정보의 처리 및 보유기간',
          content:
              '''회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.

각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:

• 회원 가입 및 관리: 회원 탈퇴 시까지
  다만, 다음의 사유가 있을 경우에는 해당 사유 종료시까지
  - 관계 법령 위반에 따른 수사·조사 등이 진행중인 경우에는 해당 수사·조사 종료시까지
  - 서비스 이용에 따른 채권·채무관계 잔존시에는 해당 채권·채무관계 정산시까지

• 상담 서비스 제공: 서비스 종료 후 3년
• 전자상거래에서의 계약·청약철회 등에 관한 기록: 5년
• 전자상거래에서의 대금결제 및 재화 등의 공급에 관한 기록: 5년
• 소비자의 불만 또는 분쟁처리에 관한 기록: 3년''',
        ),

        _buildSection(
          title: '3. 개인정보의 제3자 제공',
          content:
              '''회사는 원칙적으로 정보주체의 개인정보를 수집·이용 목적으로 명시한 범위 내에서 처리하며, 정보주체의 사전 동의 없이는 본래의 목적 범위를 초과하여 처리하거나 제3자에게 제공하지 않습니다.

다만, 다음의 경우에는 예외로 합니다:
• 정보주체가 사전에 동의한 경우
• 법률에 특별한 규정이 있거나 법령상 의무를 준수하기 위하여 불가피한 경우
• 공공기관이 법령 등에서 정하는 소관 업무의 수행을 위하여 불가피한 경우
• 정보주체 또는 그 법정대리인이 의사표시를 할 수 없는 상태에 있거나 주소불명 등으로 사전 동의를 받을 수 없는 경우로서 명백히 정보주체 또는 제3자의 급박한 생명, 신체, 재산의 이익을 위하여 필요하다고 인정되는 경우''',
        ),

        _buildSection(
          title: '4. 개인정보처리의 위탁',
          content: '''회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:

• 위탁업체: Amazon Web Services (AWS)
  - 위탁업무: 클라우드 서버 운영 및 데이터 저장
  - 위탁기간: 서비스 이용계약 종료 시까지

• 위탁업체: Google Firebase
  - 위탁업무: 사용자 인증 및 푸시 알림 서비스
  - 위탁기간: 서비스 이용계약 종료 시까지

• 위탁업체: 결제대행업체 (토스페이먼츠, KG이니시스 등)
  - 위탁업무: 결제처리 및 결제 관련 민원처리
  - 위탁기간: 결제완료 후 5년

회사는 위탁계약 체결시 개인정보보호법 제26조에 따라 위탁업무 수행목적 외 개인정보 처리금지, 기술적·관리적 보호조치, 재위탁 제한, 수탁자에 대한 관리·감독, 손해배상 등 책임에 관한 사항을 계약서 등 문서에 명시하고, 수탁자가 개인정보를 안전하게 처리하는지를 감독하고 있습니다.''',
        ),

        _buildSection(
          title: '5. 정보주체의 권리·의무 및 행사방법',
          content: '''정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:

• 개인정보 처리정지 요구권
• 개인정보 열람요구권
• 개인정보 정정·삭제요구권
• 개인정보 처리정지 요구권

권리 행사는 회사에 대해 서면, 전화, 전자우편, 모사전송(FAX) 등을 통하여 하실 수 있으며 회사는 이에 대해 지체 없이 조치하겠습니다.

정보주체가 개인정보의 오류 등에 대한 정정 또는 삭제를 요구한 경우에는 회사는 정정 또는 삭제를 완료할 때까지 당해 개인정보를 이용하거나 제공하지 않습니다.

권리 행사는 정보주체의 법정대리인이나 위임을 받은 자 등 대리인을 통하여 하실 수 있습니다.''',
        ),

        _buildSection(
          title: '6. 개인정보의 파기',
          content:
              '''회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.

정보주체로부터 동의받은 개인정보 보유기간이 경과하거나 처리목적이 달성되었음에도 불구하고 다른 법령에 따라 개인정보를 계속 보존하여야 하는 경우에는, 해당 개인정보를 별도의 데이터베이스(DB)로 옮기거나 보관장소를 달리하여 보존합니다.

개인정보 파기의 절차 및 방법은 다음과 같습니다:

• 파기절차
  - 회사는 파기 사유가 발생한 개인정보를 선정하고, 회사의 개인정보 보호책임자의 승인을 받아 개인정보를 파기합니다.

• 파기방법
  - 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용합니다
  - 종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각을 통하여 파기합니다''',
        ),

        _buildSection(
          title: '7. 개인정보 보호책임자',
          content:
              '''회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다:

• 개인정보 보호책임자
  - 성명: 홍길동
  - 직책: 개인정보보호팀장
  - 전화번호: 02-1234-5678
  - 이메일: privacy@mentalfit.co.kr

• 개인정보 보호 담당부서
  - 부서명: 개인정보보호팀
  - 담당자: 김철수
  - 전화번호: 02-1234-5679
  - 이메일: support@mentalfit.co.kr

정보주체께서는 회사의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자 및 담당부서로 문의하실 수 있습니다.''',
        ),

        _buildSection(
          title: '8. 개인정보 처리방침의 변경',
          content:
              '본 개인정보 처리방침은 시행일로부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.',
        ),

        SizedBox(height: 32.h),

        // === 문의 정보 ===
        ThemedContainer(
          useSurface: false,
          padding: EdgeInsets.all(16.w),
          borderRadius: BorderRadius.circular(12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contact_support_outlined,
                    size: 20.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  ThemedText(
                    text: '문의하기',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              const ThemedText(
                text: '개인정보 처리에 관한 문의사항이 있으시면 언제든지 연락주세요.',
                isPrimary: false,
                style: TextStyle(fontSize: 14.0),
              ),
              SizedBox(height: 8.h),
              const ThemedText(
                text: '이메일: privacy@mentalfit.co.kr\n전화: 02-1234-5678',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedText(
          text: title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        ThemedText(
          text: content,
          isPrimary: false,
          style: TextStyle(fontSize: 14.sp, height: 1.6),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}
