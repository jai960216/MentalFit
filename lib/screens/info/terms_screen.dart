import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core
import '../../core/config/app_colors.dart';

// Shared
import '../../shared/widgets/custom_app_bar.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '이용약관'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey400.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
              Icons.description_outlined,
              size: 24.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              '서비스 이용약관',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          '시행일자: 2024년 1월 1일',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 4.h),
        Text(
          '최종 개정일: 2024년 12월 1일',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTableOfContents() {
    final contents = [
      '제1조 (목적)',
      '제2조 (정의)',
      '제3조 (약관의 게시와 개정)',
      '제4조 (서비스의 제공)',
      '제5조 (이용계약의 성립)',
      '제6조 (회원정보의 변경)',
      '제7조 (개인정보보호)',
      '제8조 (이용자의 의무)',
      '제9조 (서비스 이용제한)',
      '제10조 (서비스의 중단)',
      '제11조 (손해배상)',
      '제12조 (면책조항)',
      '제13조 (분쟁해결)',
      '제14조 (기타)',
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '목차',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          ...contents.map(
            (content) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
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
          title: '제1조 (목적)',
          content:
              '''이 약관은 멘탈핏(이하 "회사")가 제공하는 스포츠 심리 상담 서비스(이하 "서비스")의 이용조건 및 절차, 이용자와 회사의 권리, 의무, 책임사항과 기타 필요한 사항을 규정함을 목적으로 합니다.''',
        ),

        _buildSection(
          title: '제2조 (정의)',
          content: '''이 약관에서 사용하는 용어의 정의는 다음과 같습니다:

1. "서비스"란 회사가 제공하는 모든 스포츠 심리 상담 관련 서비스를 의미합니다.

2. "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.

3. "회원"이란 회사에 개인정보를 제공하여 회원등록을 한 자로서, 회사의 정보를 지속적으로 제공받으며 회사가 제공하는 서비스를 계속적으로 이용할 수 있는 자를 말합니다.

4. "비회원"이란 회원에 가입하지 않고 회사가 제공하는 서비스를 이용하는 자를 말합니다.

5. "상담사"란 회사와 계약을 맺고 전문적인 심리 상담 서비스를 제공하는 자를 말합니다.''',
        ),

        _buildSection(
          title: '제3조 (약관의 게시와 개정)',
          content: '''1. 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.

2. 회사는 관련 법령을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.

3. 회사가 약관을 개정할 경우에는 적용일자 및 개정사유를 명시하여 현행약관과 함께 서비스의 초기화면에 그 적용일자 7일 이전부터 적용일자 전일까지 공지합니다.

4. 이용자는 개정된 약관에 대해 동의하지 않을 권리가 있으며, 개정된 약관에 동의하지 않는 경우 서비스 이용을 중단하고 탈퇴할 수 있습니다.''',
        ),

        _buildSection(
          title: '제4조 (서비스의 제공)',
          content: '''1. 회사는 다음과 같은 서비스를 제공합니다:

• AI 기반 심리 상담 서비스
  - 24시간 언제든지 이용 가능한 AI 챗봇 상담
  - 개인 맞춤형 심리 상담 및 조언 제공

• 전문 상담사와의 1:1 상담 서비스
  - 자격을 갖춘 전문 상담사와의 실시간 상담
  - 화상, 음성, 채팅을 통한 다양한 상담 방식 제공

• 자가진단 및 심리 검사 서비스
  - 스트레스, 불안, 우울 등의 자가진단 도구 제공
  - 개인 맞춤형 심리 검사 및 결과 분석

• 상담 기록 관리 서비스
  - 상담 내역 및 진행 상황 기록
  - 개인 성장 및 변화 추적 관리

2. 회사는 서비스의 품질 향상을 위해 서비스의 내용을 수정하거나 변경할 수 있습니다.

3. 회사는 필요한 경우 서비스의 일부 또는 전부를 제3자에게 위탁할 수 있습니다.''',
        ),

        _buildSection(
          title: '제5조 (이용계약의 성립)',
          content:
              '''1. 이용계약은 이용자가 회사가 정한 회원가입 양식에 따라 회원정보를 기입한 후 이 약관에 동의한다는 의사표시를 함으로써 신청합니다.

2. 회사는 제1항과 같이 이용자가 신청한 경우 서비스 이용을 승낙합니다.

3. 회사는 다음 각 호에 해당하는 신청에 대하여는 승낙을 하지 않거나 사후에 이용계약을 해지할 수 있습니다:

• 가입신청자가 이 약관에 의하여 이전에 회원자격을 상실한 적이 있는 경우
• 실명이 아니거나 타인의 명의를 이용한 경우
• 허위의 정보를 기재하거나, 회사가 제시하는 내용을 기재하지 않은 경우
• 미성년자가 법정대리인의 동의를 얻지 아니한 경우
• 이용자의 귀책사유로 인하여 승인이 불가능하거나 기타 규정한 제반 사항을 위반하며 신청한 경우''',
        ),

        _buildSection(
          title: '제6조 (회원정보의 변경)',
          content: '''1. 회원은 개인정보관리화면을 통하여 언제든지 본인의 개인정보를 열람하고 수정할 수 있습니다.

2. 회원은 회원가입 시 기재한 사항이 변경되었을 경우 온라인으로 수정을 하거나 전자우편 기타 방법으로 회사에 그 변경사항을 알려야 합니다.

3. 제2항의 변경사항을 회사에 알리지 않아 발생한 불이익에 대하여는 회원에게 책임이 있습니다.''',
        ),

        _buildSection(
          title: '제7조 (개인정보보호)',
          content: '''1. 회사는 이용자의 개인정보를 보호하기 위하여 관련 법령이 정하는 바에 따라 노력합니다.

2. 개인정보의 보호 및 사용에 대해서는 관련 법령 및 회사의 개인정보처리방침이 적용됩니다.

3. 회사는 이용자의 개인정보를 본인의 승낙 없이 제3자에게 누설하거나 배포하지 않습니다. 단, 관련 법령에 의해 관계기관으로부터 요구받은 경우는 예외로 합니다.''',
        ),

        _buildSection(
          title: '제8조 (이용자의 의무)',
          content: '''1. 이용자는 다음 행위를 하여서는 안 됩니다:

• 신청 또는 변경 시 허위내용의 등록
• 타인의 정보 도용
• 회사가 게시한 정보의 변경
• 회사 및 제3자의 저작권 등 지적재산권에 대한 침해
• 회사 및 제3자의 명예를 손상시키거나 업무를 방해하는 행위
• 외설 또는 폭력적인 메시지, 화상, 음성, 기타 공서양속에 반하는 정보를 서비스에 공개 또는 게시하는 행위
• 서비스를 이용하여 얻은 정보를 회사의 사전 승낙 없이 복제하거나 이를 출판 및 방송 등에 사용하거나 제3자에게 제공하는 행위

2. 이용자는 관계 법령, 이 약관의 규정, 이용안내 및 서비스상에 공지한 주의사항, 회사가 통지하는 사항 등을 준수하여야 하며, 기타 회사의 업무에 방해되는 행위를 하여서는 안 됩니다.''',
        ),

        _buildSection(
          title: '제9조 (서비스 이용제한)',
          content:
              '''1. 회사는 이용자가 제8조의 의무를 위반하거나 서비스의 정상적인 운영을 방해한 경우, 경고, 일시정지, 영구이용정지 등으로 서비스 이용을 단계적으로 제한할 수 있습니다.

2. 회사는 전항에도 불구하고, 저작권법 위반, 명예훼손 등 관련 법령 위반, 개인정보 도용 및 타인의 개인정보 무단수집 등의 행위에 대해서는 즉시 영구이용정지를 할 수 있습니다.

3. 회사의 서비스 이용제한에 대하여 이용자는 회사가 정한 절차에 따라 이의신청을 할 수 있습니다.''',
        ),

        _buildSection(
          title: '제10조 (서비스의 중단)',
          content:
              '''1. 회사는 컴퓨터 등 정보통신설비의 보수점검, 교체 및 고장, 통신의 두절 등의 사유가 발생한 경우에는 서비스의 제공을 일시적으로 중단할 수 있습니다.

2. 회사는 제1항의 사유로 서비스의 제공이 중단된 경우에 대하여 이용자 또는 제3자가 입은 손해에 대해서는 책임을 지지 않습니다. 단, 회사에 고의 또는 중과실이 있는 경우에는 그러하지 아니합니다.

3. 회사는 사업종목의 전환, 사업의 포기, 업체 간의 통합 등의 이유로 서비스를 제공할 수 없게 되는 경우에는 제3조 제3항에 정한 방법으로 이용자에게 통지하고 서비스 제공을 중단할 수 있습니다.''',
        ),

        _buildSection(
          title: '제11조 (손해배상)',
          content:
              '''1. 회사는 무료로 제공되는 서비스와 관련하여 이용자에게 어떠한 손해가 발생하더라도 회사가 고의 또는 중과실로 인한 손해의 경우를 제외하고 이에 대하여 책임을 지지 않습니다.

2. 회사가 개인정보보호법 등 관련 법령에서 정하는 개인정보보호 의무를 위반으로 인하여 이용자에게 손해가 발생한 경우 이용자는 손해배상을 청구할 수 있습니다.

3. 회사는 이용자가 서비스에 게재한 정보, 자료, 사실의 신뢰도, 정확성 등 내용에 관하여는 책임을 지지 않으며, 이용자 상호간 및 이용자와 제3자 상호간에 서비스를 매개로 발생한 분쟁에 대해 개입할 의무가 없고, 이로 인한 손해를 배상할 책임도 없습니다.''',
        ),

        _buildSection(
          title: '제12조 (면책조항)',
          content:
              '''1. 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.

2. 회사는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대하여는 책임을 지지 않습니다.

3. 회사는 이용자가 서비스를 이용하여 기대하는 수익을 얻지 못하거나 상실한 것에 대하여는 책임을 지지 않습니다.

4. 회사는 이용자 간 또는 이용자와 제3자 간에 서비스를 매개로 하여 물품거래 혹은 금전적 거래 등과 관련하여 어떠한 책임도 부담하지 아니하고, 이용자가 서비스의 이용과 관련하여 기대하는 이익에 관하여 책임을 부담하지 않습니다.

5. 상담 서비스는 전문적인 의료 서비스를 대체할 수 없으며, 응급상황이나 심각한 정신건강 문제가 있는 경우 반드시 전문의료기관의 도움을 받아야 합니다.''',
        ),

        _buildSection(
          title: '제13조 (분쟁해결)',
          content:
              '''1. 회사는 이용자가 제기하는 정당한 의견이나 불만을 반영하고 그 피해를 보상처리하기 위하여 피해보상처리기구를 설치·운영합니다.

2. 회사는 이용자로부터 제출되는 불만사항 및 의견은 우선적으로 그 사항을 처리합니다. 다만, 신속한 처리가 곤란한 경우에는 이용자에게 그 사유와 처리일정을 즉시 통보해 드립니다.

3. 회사와 이용자 간에 발생한 전자상거래 분쟁에 관하여는 소비자분쟁조정위원회의 조정에 따를 수 있습니다.

4. 회사와 이용자 간에 발생한 분쟁은 대한민국 법을 적용하며, 분쟁이 발생할 경우 회사의 본사 소재지를 관할하는 법원을 전속관할 법원으로 합니다.''',
        ),

        _buildSection(
          title: '제14조 (기타)',
          content: '''1. 이 약관은 대한민국 법률에 따라 규율되고 해석됩니다.

2. 이 약관에서 규정하지 않은 사항과 이 약관의 해석에 관하여는 전자상거래 등에서의 소비자보호에 관한 법률, 약관의 규제에 관한 법률, 정보통신망 이용촉진 및 정보보호 등에 관한 법률 등 관련법령 또는 상관례에 따릅니다.

3. 회사는 필요한 경우 특정 서비스에 관하여 별도의 이용약관 및 정책을 둘 수 있으며, 해당 내용이 이 약관과 상충할 경우에는 별도의 이용약관 및 정책이 우선 적용됩니다.

[부칙]
이 약관은 2024년 1월 1일부터 적용됩니다.''',
        ),

        SizedBox(height: 32.h),

        // === 연락처 정보 ===
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contact_support_outlined,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '문의 및 신고',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                '서비스 이용 중 문의사항이나 신고할 내용이 있으시면 언제든지 연락주세요.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '고객센터: 1588-1234\n이메일: support@mentalfit.co.kr\n운영시간: 평일 09:00 - 18:00',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
