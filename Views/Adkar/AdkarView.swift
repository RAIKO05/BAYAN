import SwiftUI

// MARK: - Adkar Model
public struct DikrItem: Identifiable, Hashable {
    public let id = UUID()
    public let arabic: String
    public let translation: String
    public let virtue: String
    public let targetCount: Int
    public let category: AdkarCategory

    public enum AdkarCategory: String, CaseIterable, Identifiable {
        case morning = "Morning (الصباح)"
        case evening = "Evening (المساء)"
        case afterPrayer = "After Prayer (بعد الصلاة)"
        case sleep = "Sleep (النوم)"
        case tasbih = "Tasbih (تسابيح)"

        public var id: String { rawValue }

        public var shortTitle: String {
            switch self {
            case .morning: return "الصباح"
            case .evening: return "المساء"
            case .afterPrayer: return "بعد الصلاة"
            case .sleep: return "النوم"
            case .tasbih: return "تسابيح"
            }
        }
    }
}

// Curated authentic Adkar dataset
public struct AdkarCatalog {
    public static let allItems: [DikrItem] = [
        // Morning
        DikrItem(
            arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.",
            translation: "We have reached the morning and at this very time unto Allah belongs all sovereignty...",
            virtue: "حفظ وبركة اليوم",
            targetCount: 1,
            category: .morning
        ),
        DikrItem(
            arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.",
            translation: "O Allah, You are my Lord, there is none worthy of worship except You...",
            virtue: "سيد الاستغفار (من قاله موقناً به دخل الجنة)",
            targetCount: 1,
            category: .morning
        ),
        DikrItem(
            arabic: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.",
            translation: "In the Name of Allah with Whose Name nothing can cause harm in earth or heaven...",
            virtue: "لم يضره شيء (3 مرات)",
            targetCount: 3,
            category: .morning
        ),
        DikrItem(
            arabic: "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا.",
            translation: "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad as my Prophet.",
            virtue: "كان حقاً على الله أن يرضيه (3 مرات)",
            targetCount: 3,
            category: .morning
        ),
        DikrItem(
            arabic: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.",
            translation: "O Ever Living, O Self-Subsisting, by Your mercy I seek assistance...",
            virtue: "دعاء تفريج الهم",
            targetCount: 1,
            category: .morning
        ),

        // Evening
        DikrItem(
            arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ.",
            translation: "We have reached the evening and at this very time unto Allah belongs all sovereignty...",
            virtue: "حفظ الليلة",
            targetCount: 1,
            category: .evening
        ),
        DikrItem(
            arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.",
            translation: "I seek refuge in the perfect words of Allah from the evil of what He has created.",
            virtue: "حفظ من الهوام والسموم (3 مرات)",
            targetCount: 3,
            category: .evening
        ),
        DikrItem(
            arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي.",
            translation: "O Allah, I ask You for forgiveness and well-being in this world and the Hereafter...",
            virtue: "حفظ الجوانب الأربعة",
            targetCount: 1,
            category: .evening
        ),

        // After Prayer
        DikrItem(
            arabic: "أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ. اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.",
            translation: "I seek forgiveness of Allah (3 times). O Allah, You are Peace and from You comes peace...",
            virtue: "دبر كل صلاة مكتوبة",
            targetCount: 1,
            category: .afterPrayer
        ),
        DikrItem(
            arabic: "سُبْحَانَ اللَّهِ (33) • الْحَمْدُ لِلَّهِ (33) • اللَّهُ أَكْبَرُ (33) • لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.",
            translation: "Glory be to Allah (33), Praise be to Allah (33), Allah is the Greatest (33)...",
            virtue: "غُفرت خطاياه وإن كانت مثل زبد البحر",
            targetCount: 33,
            category: .afterPrayer
        ),

        // Sleep
        DikrItem(
            arabic: "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.",
            translation: "In Your name, my Lord, I lay down my side and in Your name I raise it up...",
            virtue: "أذكار قبل النوم",
            targetCount: 1,
            category: .sleep
        ),
        DikrItem(
            arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.",
            translation: "O Allah, save me from Your punishment on the Day You resurrect Your slaves.",
            virtue: "يقال ثلاث مرات باليد اليمنى تحت الخد",
            targetCount: 3,
            category: .sleep
        ),

        // Tasbih
        DikrItem(
            arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ.",
            translation: "Glory be to Allah and His is the praise, Glory be to Allah the Supreme.",
            virtue: "كلمتان خفيفتان على اللسان ثقيلتان في الميزان",
            targetCount: 100,
            category: .tasbih
        ),
        DikrItem(
            arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ.",
            translation: "There is no power and no strength except with Allah, the Most High, the Supreme.",
            virtue: "كنز من كنوز الجنة",
            targetCount: 33,
            category: .tasbih
        )
    ]
}

// MARK: - Adkar View
public struct AdkarView: View {
    @State private var selectedCategory: DikrItem.AdkarCategory = .morning
    @State private var currentCounts: [UUID: Int] = [:]
    @State private var showingHisnAlMuslim: Bool = false
    @State private var showingDigitalTasbih: Bool = false
    @State private var themeManager = AppThemeManager.shared

    public init() {}

    private var filteredItems: [DikrItem] {
        AdkarCatalog.allItems.filter { $0.category == selectedCategory }
    }

    private var completedCount: Int {
        filteredItems.filter { (currentCounts[$0.id] ?? 0) >= $0.targetCount }.count
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Theme Unified Background
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Title Header
                        VStack(spacing: 4) {
                            Text("أَذْكَارُ الْمُسْلِمِ")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, BayanTheme.goldSoft],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("DAILY SUPPLICATIONS & DIGITAL TASBIH")
                                .font(.system(size: 9.5, weight: .bold))
                                .tracking(2.5)
                                .foregroundColor(BayanTheme.gold.opacity(0.85))
                        }
                        .padding(.top, 10)

                        // Hisn al-Muslim Complete Fortress Launcher
                        Button {
                            showingHisnAlMuslim = true
                            triggerHaptic()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(BayanTheme.gold.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "shield.checkered")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(BayanTheme.gold)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hisn al-Muslim (حصن المسلم)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white)
                                    Text("Complete Fortress of the Muslim • 7 Categories & Virtues")
                                        .font(.caption2)
                                        .foregroundColor(BayanTheme.goldSoft.opacity(0.85))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(BayanTheme.gold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(BayanTheme.gold.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        // Interactive 3D Digital Tasbih Launcher
                        Button {
                            showingDigitalTasbih = true
                            triggerHaptic()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.18, green: 0.85, blue: 0.50).opacity(0.18))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "circle.circle.fill")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(Color(red: 0.18, green: 0.85, blue: 0.50))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Interactive 3D Digital Tasbih")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundColor(.white)
                                        Text("المسبحة")
                                            .font(.caption2.weight(.bold))
                                            .foregroundColor(Color(red: 0.18, green: 0.85, blue: 0.50))
                                    }
                                    Text("Physical Bead String • Blind Touch Mode • Custom Targets")
                                        .font(.caption2)
                                        .foregroundColor(BayanTheme.goldSoft.opacity(0.85))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(BayanTheme.gold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.18, green: 0.85, blue: 0.50).opacity(0.35), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        // Category Filter Horizontal Scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DikrItem.AdkarCategory.allCases) { cat in
                                    let isSelected = cat == selectedCategory
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedCategory = cat
                                        }
                                    } label: {
                                        Text(cat.shortTitle)
                                            .font(.caption.weight(isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? BayanTheme.goldSoft : .white.opacity(0.65))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                isSelected ?
                                                    BayanTheme.gold.opacity(0.18) :
                                                    Color.white.opacity(0.05)
                                            )
                                            .overlay(
                                                Capsule().stroke(
                                                    isSelected ? BayanTheme.gold.opacity(0.5) : Color.white.opacity(0.1),
                                                    lineWidth: 1
                                                )
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Progress Tracker Card
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("COMPLETED")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(BayanTheme.gold)
                                    .tracking(1)

                                Text("\(completedCount) of \(filteredItems.count) Completed")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            // Reset Counts Button
                            Button {
                                for item in filteredItems {
                                    currentCounts[item.id] = 0
                                }
                                triggerHaptic()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(BayanTheme.goldSoft)
                                    .padding(8)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .liquidGlass(cornerRadius: 18)
                        .padding(.horizontal)

                        // Adkar List
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 12)], spacing: 12) {
                            ForEach(filteredItems) { item in
                                let count = currentCounts[item.id] ?? 0
                                let isDone = count >= item.targetCount

                                DikrCardRow(
                                    item: item,
                                    currentCount: count,
                                    isDone: isDone
                                ) {
                                    if count < item.targetCount {
                                        currentCounts[item.id] = count + 1
                                        triggerHaptic()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 110) // Clearance for floating liquid glass bar
                    }
                    .padding(.top, 8)
                }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
            }
            .navigationTitle("Adkar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingHisnAlMuslim) {
                HisnAlMuslimView()
            }
            .fullScreenCover(isPresented: $showingDigitalTasbih) {
                DigitalTasbihView()
            }
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Dikr Card Row
private struct DikrCardRow: View {
    let item: DikrItem
    let currentCount: Int
    let isDone: Bool
    var onCountTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with Virtue Badge
            HStack {
                Text(item.virtue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(BayanTheme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BayanTheme.gold.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                Text("Target: \(item.targetCount)x")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }

            // Arabic Text
            Text(item.arabic)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(.white)
                .lineSpacing(8)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Translation & Interactive Tasbih Button
            HStack(alignment: .center, spacing: 12) {
                Text(item.translation)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
                    .italic()
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Interactive Tap Counter Button
                Button(action: onCountTap) {
                    ZStack {
                        Circle()
                            .fill(
                                isDone ?
                                    LinearGradient(colors: [Color.green.opacity(0.8), Color.teal], startPoint: .top, endPoint: .bottom) :
                                    LinearGradient(colors: [BayanTheme.gold, BayanTheme.goldSoft], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: isDone ? Color.green.opacity(0.3) : BayanTheme.gold.opacity(0.3), radius: 6, y: 2)

                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                        } else {
                            Text("\(item.targetCount - currentCount)")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(BayanTheme.obsidian)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18, isGoldBorder: isDone)
    }
}
