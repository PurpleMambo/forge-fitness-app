import SwiftUI
import UIKit

// MARK: - Equipment data model

struct EquipmentItem: Identifiable {
    let id: String
    let name: String
    let sfSymbol: String
    let detail: String

    var imageURL: URL? {
        let ext = id == "parallettes" ? "jpg" : "png"
        return URL(string: "https://neomyrexkfgrsrcqvnsb.supabase.co/storage/v1/object/public/equipment-images/equipment_renamed/\(id).\(ext)")
    }
}

struct EquipmentCategory: Identifiable {
    let id: String
    let title: String
    let items: [EquipmentItem]
}

let allEquipmentCategories: [EquipmentCategory] = [

    .init(id: "free_weights", title: "Free weights", items: [
        .init(id: "dumbbells",       name: "Dumbbells",            sfSymbol: "dumbbell.fill", detail: "2, 4, 6, 8, 10, 12, 15, 20..."),
        .init(id: "kettlebells",     name: "Kettlebells",          sfSymbol: "dumbbell",      detail: "4, 8, 12, 16, 20, 24, 32..."),
        .init(id: "ez_curl_bar",     name: "EZ-Curl Bar",          sfSymbol: "dumbbell.fill", detail: "Angled grip, ~10 kg"),
        .init(id: "swiss_bar",       name: "Swiss Bar",            sfSymbol: "dumbbell",      detail: "Multi-grip, neutral press"),
        .init(id: "trap_bar",        name: "Trap Bar / Hex Bar",   sfSymbol: "hexagon.fill",  detail: "Dead lift & carry"),
        .init(id: "medicine_ball",   name: "Medicine Ball",        sfSymbol: "circle.fill",   detail: "2, 4, 6, 8, 10 kg"),
        .init(id: "slam_ball",       name: "Slam Ball",            sfSymbol: "circle.fill",   detail: "Deadweight impact ball"),
        .init(id: "wall_ball",       name: "Wall Ball",            sfSymbol: "circle",        detail: "6–9 kg, soft shell"),
        .init(id: "sandbag",         name: "Sandbag",              sfSymbol: "bag.fill",      detail: "10–100 kg loadable"),
        .init(id: "steel_mace",      name: "Steel Mace",           sfSymbol: "line.diagonal", detail: "7–30 lb offset load"),
    ]),

    .init(id: "bars_plates", title: "Bars & plates", items: [
        .init(id: "barbell",          name: "Olympic Barbell",      sfSymbol: "dumbbell.fill", detail: "Standard 20 kg, 220 cm"),
        .init(id: "plates",           name: "Iron Plates",          sfSymbol: "circle.fill",   detail: "1.25, 2.5, 5, 10, 20 kg"),
        .init(id: "bumper_plates",    name: "Bumper Plates",        sfSymbol: "circle",        detail: "Rubber coated, drop-safe"),
        .init(id: "safety_squat_bar", name: "Safety Squat Bar",     sfSymbol: "dumbbell",      detail: "Cambered yoke bar"),
        .init(id: "cambered_bar",     name: "Cambered Bar",         sfSymbol: "dumbbell",      detail: "Offset load position"),
        .init(id: "axle_bar",         name: "Axle / Thick Bar",     sfSymbol: "dumbbell",      detail: "2\" diameter for grip"),
        .init(id: "log_bar",          name: "Log Bar",              sfSymbol: "cylinder",      detail: "Neutral grip, Strongman"),
    ]),

    .init(id: "racks_benches", title: "Racks & benches", items: [
        .init(id: "squat_rack",          name: "Squat Rack / Power Rack", sfSymbol: "square.3.layers.3d.top.filled", detail: "Full cage with safeties"),
        .init(id: "half_rack",           name: "Half Rack",               sfSymbol: "square.3.layers.3d",           detail: "Open-back squat stand"),
        .init(id: "adjustable_bench",    name: "Adjustable Bench",        sfSymbol: "rectangle.fill",               detail: "Flat, incline, decline"),
        .init(id: "flat_bench",          name: "Flat Bench",              sfSymbol: "rectangle.fill",               detail: "Fixed flat pressing bench"),
        .init(id: "preacher_bench",      name: "Preacher Curl Bench",     sfSymbol: "rectangle.portrait.fill",      detail: "Angled arm curl pad"),
        .init(id: "hyperextension",      name: "Hyperextension Bench",    sfSymbol: "rectangle.portrait",           detail: "45° back extension"),
        .init(id: "hip_thrust_bench",    name: "Hip Thrust Bench",        sfSymbol: "rectangle.fill",               detail: "Padded glute pad"),
        .init(id: "ghd",                 name: "Glute Ham Developer",     sfSymbol: "figure.gymnastics",            detail: "GHD raises & sit-ups"),
        .init(id: "sissy_squat",         name: "Sissy Squat Machine",     sfSymbol: "figure.squats",               detail: "Quad isolation"),
        .init(id: "dip_station",         name: "Dip Station",             sfSymbol: "figure.core.training",         detail: "Parallel dip bars"),
    ]),

    .init(id: "cable_machines", title: "Cable & pulley machines", items: [
        .init(id: "cable_machine",      name: "Dual Cable Machine",  sfSymbol: "arrow.up.and.down.circle.fill", detail: "High / low adjustable"),
        .init(id: "functional_trainer", name: "Functional Trainer",  sfSymbol: "arrow.up.and.down.circle",      detail: "360° cable movement"),
        .init(id: "lat_pulldown",       name: "Lat Pulldown",        sfSymbol: "arrow.down.circle.fill",        detail: "Overhead cable pull"),
        .init(id: "cable_row",          name: "Seated Cable Row",    sfSymbol: "arrow.backward.circle.fill",    detail: "Horizontal pull"),
        .init(id: "cable_crossover",    name: "Cable Crossover",     sfSymbol: "arrow.left.and.right.circle",   detail: "Fly / crossover station"),
        .init(id: "tricep_station",     name: "Tricep Pushdown",     sfSymbol: "arrow.down.circle",             detail: "Rope / bar attachment"),
    ]),

    .init(id: "weight_machines", title: "Weight machines", items: [
        .init(id: "smith_machine",          name: "Smith Machine",             sfSymbol: "arrow.up.arrow.down",          detail: "Guided barbell system"),
        .init(id: "leg_press",              name: "Leg Press",                 sfSymbol: "figure.strengthtraining.functional", detail: "45° sled or seated"),
        .init(id: "hack_squat",             name: "Hack Squat Machine",        sfSymbol: "figure.strengthtraining.traditional", detail: "Fixed squat path"),
        .init(id: "pendulum_squat",         name: "Pendulum Squat",            sfSymbol: "figure.squats",               detail: "Arc-path loaded squat"),
        .init(id: "belt_squat",             name: "Belt Squat Machine",        sfSymbol: "figure.mind.and.body",         detail: "Spine-unloaded squat"),
        .init(id: "leg_extension",          name: "Leg Extension Machine",     sfSymbol: "figure.run",                   detail: "Quad isolation"),
        .init(id: "leg_curl",               name: "Leg Curl Machine",          sfSymbol: "figure.cooldown",              detail: "Seated or lying hamstring"),
        .init(id: "seated_calf_raise",      name: "Seated Calf Raise",         sfSymbol: "figure.walk",                  detail: "Soleus isolation"),
        .init(id: "standing_calf_raise",    name: "Standing Calf Raise",       sfSymbol: "figure.walk.motion",           detail: "Gastrocnemius focus"),
        .init(id: "hip_abductor",           name: "Hip Abductor Machine",      sfSymbol: "arrow.left.and.right",         detail: "Outer glute / hip"),
        .init(id: "hip_adductor",           name: "Hip Adductor Machine",      sfSymbol: "arrow.left.and.right",         detail: "Inner thigh"),
        .init(id: "chest_press_machine",    name: "Chest Press Machine",       sfSymbol: "arrow.forward.circle.fill",    detail: "Horizontal press, guided"),
        .init(id: "pec_deck",               name: "Pec Deck / Butterfly",      sfSymbol: "arrow.left.and.right.circle",  detail: "Chest fly isolation"),
        .init(id: "shoulder_press_machine", name: "Shoulder Press Machine",    sfSymbol: "arrow.up.circle.fill",         detail: "Overhead guided press"),
        .init(id: "lateral_raise_machine",  name: "Lateral Raise Machine",     sfSymbol: "arrow.up.and.down",            detail: "Side delt isolation"),
        .init(id: "rear_delt_machine",      name: "Rear Delt Machine",         sfSymbol: "arrow.backward.circle",        detail: "Reverse fly pattern"),
        .init(id: "seated_row_machine",     name: "Chest-Supported Row",       sfSymbol: "arrow.backward.circle.fill",   detail: "Chest pad rowing"),
        .init(id: "tbar_row",               name: "T-Bar Row Machine",         sfSymbol: "arrow.backward.circle",        detail: "Plate-loaded row"),
        .init(id: "preacher_curl_machine",  name: "Preacher Curl Machine",     sfSymbol: "arrow.clockwise.circle",       detail: "Bicep isolation, supported"),
        .init(id: "assisted_pullup",        name: "Assisted Pull-up Machine",  sfSymbol: "arrow.up.circle",              detail: "Counterweight assistance"),
        .init(id: "back_extension_machine", name: "Back Extension Machine",    sfSymbol: "figure.cooldown",              detail: "Lumbar & glute extension"),
    ]),

    .init(id: "cardio", title: "Cardio equipment", items: [
        .init(id: "treadmill",        name: "Treadmill",              sfSymbol: "figure.run",            detail: "Speed & incline control"),
        .init(id: "rowing_machine",   name: "Rowing Machine",         sfSymbol: "figure.rower",          detail: "Full body ergometer"),
        .init(id: "assault_bike",     name: "Assault / Air Bike",     sfSymbol: "bicycle.circle.fill",   detail: "Arms + legs full effort"),
        .init(id: "stationary_bike",  name: "Stationary Bike",        sfSymbol: "bicycle",               detail: "Upright cycling"),
        .init(id: "spin_bike",        name: "Spin Bike",              sfSymbol: "bicycle.fill",          detail: "Heavy flywheel, road feel"),
        .init(id: "elliptical",       name: "Elliptical",             sfSymbol: "figure.elliptical",     detail: "Low-impact cross-trainer"),
        .init(id: "stair_climber",    name: "Stair Climber",          sfSymbol: "figure.stair.stepper",  detail: "Step mill or StairMaster"),
        .init(id: "ski_erg",          name: "Ski Erg",                sfSymbol: "figure.skiing.downhill", detail: "Overhead pull cardio"),
        .init(id: "jump_rope",        name: "Jump Rope",              sfSymbol: "lasso",                 detail: "Speed or weighted rope"),
        .init(id: "sled",             name: "Push / Pull Sled",       sfSymbol: "arrow.right.circle.fill", detail: "Loaded pushing & dragging"),
        .init(id: "battle_ropes",     name: "Battle Ropes",           sfSymbol: "waveform",              detail: "Wave training, 15 m"),
    ]),

    .init(id: "bodyweight_gymnastics", title: "Bodyweight & gymnastics", items: [
        .init(id: "pullup_bar",       name: "Pull-up Bar",            sfSymbol: "figure.strengthtraining.traditional", detail: "Wall-mounted or doorframe"),
        .init(id: "gymnastic_rings",  name: "Gymnastic Rings",        sfSymbol: "circle.circle.fill",   detail: "Suspended wooden rings"),
        .init(id: "parallettes",      name: "Parallettes",            sfSymbol: "square.fill",           detail: "Low parallel bars"),
        .init(id: "ab_wheel",         name: "Ab Wheel",               sfSymbol: "circle.fill",           detail: "Roll-out core trainer"),
        .init(id: "captains_chair",   name: "Captain's Chair",        sfSymbol: "rectangle.portrait.fill", detail: "Vertical knee raise"),
        .init(id: "roman_chair",      name: "Roman Chair",            sfSymbol: "rectangle.fill",        detail: "Hyperextension / sit-up"),
        .init(id: "plyo_box",         name: "Plyo Box",               sfSymbol: "square.fill",           detail: "20\", 24\", 30\" box jumps"),
    ]),

    .init(id: "functional_accessories", title: "Functional & accessories", items: [
        .init(id: "resistance_bands", name: "Resistance Bands",       sfSymbol: "lasso",              detail: "Light to heavy loop bands"),
        .init(id: "mini_bands",       name: "Mini Bands",             sfSymbol: "circle",             detail: "Hip & glute activation"),
        .init(id: "trx",              name: "TRX / Suspension",       sfSymbol: "link",               detail: "Suspension trainer system"),
        .init(id: "foam_roller",      name: "Foam Roller",            sfSymbol: "cylinder",           detail: "Recovery & mobility"),
        .init(id: "lacrosse_ball",    name: "Lacrosse / Massage Ball",sfSymbol: "circle.dotted",      detail: "Trigger point release"),
        .init(id: "yoga_mat",         name: "Yoga / Exercise Mat",    sfSymbol: "rectangle.fill",     detail: "Floor work & stretching"),
        .init(id: "ab_mat",           name: "Ab Mat",                 sfSymbol: "rectangle.portrait", detail: "Sit-up support pad"),
        .init(id: "weight_belt",      name: "Weight Belt",            sfSymbol: "oval.fill",          detail: "Lumbar support for lifting"),
        .init(id: "dip_belt",         name: "Dip Belt",               sfSymbol: "link.badge.plus",    detail: "Add weight to dips & pull-ups"),
        .init(id: "lifting_straps",   name: "Lifting Straps",         sfSymbol: "hand.raised.fill",   detail: "Wrist wraps for heavy pulls"),
        .init(id: "chains",           name: "Chains",                 sfSymbol: "link.circle.fill",   detail: "Accommodating resistance"),
        .init(id: "fat_gripz",        name: "Fat Gripz",              sfSymbol: "hand.raised.circle", detail: "Thick bar attachment"),
        .init(id: "parallettes_mini", name: "Yoga Blocks",            sfSymbol: "square",             detail: "Mobility & stretching aid"),
        .init(id: "tire",             name: "Tire",                   sfSymbol: "circle.fill",        detail: "Flip, drag or hammer"),
    ]),
]

// MARK: - Default equipment per gym size

func defaultEquipment(for gymSize: String) -> Set<String> {
    switch gymSize {
    case "Large Gym":
        return [
            "dumbbells", "kettlebells", "ez_curl_bar", "swiss_bar",
            "barbell", "plates", "bumper_plates",
            "squat_rack", "adjustable_bench", "flat_bench", "preacher_bench", "dip_station",
            "cable_machine", "functional_trainer", "lat_pulldown", "cable_row", "cable_crossover", "tricep_station",
            "smith_machine", "leg_press", "hack_squat", "leg_extension", "leg_curl",
            "seated_calf_raise", "standing_calf_raise", "hip_abductor", "hip_adductor",
            "chest_press_machine", "pec_deck", "shoulder_press_machine", "lateral_raise_machine",
            "rear_delt_machine", "seated_row_machine", "assisted_pullup", "back_extension_machine",
            "treadmill", "rowing_machine", "assault_bike", "stationary_bike", "elliptical", "stair_climber",
            "pullup_bar", "captains_chair", "plyo_box",
            "resistance_bands", "foam_roller", "weight_belt",
        ]
    case "Small Gym":
        return [
            "dumbbells", "kettlebells", "ez_curl_bar",
            "barbell", "plates",
            "squat_rack", "adjustable_bench", "flat_bench",
            "cable_machine", "lat_pulldown", "cable_row",
            "leg_press", "leg_extension", "leg_curl",
            "treadmill", "stationary_bike",
            "pullup_bar", "dip_station", "assisted_pullup",
            "resistance_bands", "foam_roller",
        ]
    case "Garage Gym":
        return [
            "dumbbells", "kettlebells", "ez_curl_bar",
            "barbell", "plates", "bumper_plates",
            "squat_rack", "adjustable_bench", "flat_bench",
            "pullup_bar", "dip_station", "gymnastic_rings",
            "resistance_bands", "foam_roller", "plyo_box",
            "weight_belt", "lifting_straps",
        ]
    case "At Home":
        return [
            "dumbbells", "kettlebells",
            "resistance_bands", "mini_bands",
            "pullup_bar",
            "foam_roller", "yoga_mat", "lacrosse_ball",
            "jump_rope", "ab_wheel", "trx",
        ]
    default:
        return []
    }
}

// MARK: - View

struct NewOnboardingFlow_EquipmentReviewStep: View {
    let model: NewOnboardingFlowViewModel

    @State private var selectedEquipment: Set<String>
    @State private var expandedCategories: Set<String> = []
    @State private var searchText = ""
    @State private var appeared = false

    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private let previewCount = 3

    init(model: NewOnboardingFlowViewModel) {
        self.model = model
        _selectedEquipment = State(initialValue: defaultEquipment(for: model.gymSizeAnswer))
    }

    private var filteredCategories: [EquipmentCategory] {
        guard !searchText.isEmpty else { return allEquipmentCategories }
        return allEquipmentCategories.compactMap { cat in
            let filtered = cat.items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            return filtered.isEmpty ? nil : EquipmentCategory(id: cat.id, title: cat.title, items: filtered)
        }
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                gymEquipmentNavBar(
                    onBack: model.goBack,
                    onSkip: { model.skipGymStep() }
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Review your selected equipment.")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.primary)

                            Text("We selected these based on where you train. You can edit this now or adjust later.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(duration: 0.6), value: appeared)

                        VStack(spacing: 16) {
                            ForEach(filteredCategories) { category in
                                categorySection(category)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.6).delay(0.1), value: appeared)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .safeAreaInset(edge: .bottom) { bottomPanel }
        .onAppear {
            haptic.prepare()
            withAnimation(.spring(duration: 0.7)) { appeared = true }
        }
    }

    // MARK: - Category section

    private func categorySection(_ category: EquipmentCategory) -> some View {
        let isExpanded = expandedCategories.contains(category.id) || !searchText.isEmpty
        let visibleItems = isExpanded ? category.items : Array(category.items.prefix(previewCount))
        let hasMore = category.items.count > previewCount

        return VStack(alignment: .leading, spacing: 8) {
            Text(category.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    equipmentRow(item)

                    if index < visibleItems.count - 1 || (hasMore && !isExpanded) {
                        Rectangle()
                            .fill(Color.white.opacity(0.09))
                            .frame(height: 0.5)
                            .padding(.leading, 72)
                    }
                }

                if hasMore && !isExpanded {
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            expandedCategories.insert(category.id)
                        }
                    } label: {
                        HStack {
                            Text("See all \(category.title.lowercased())")
                                .font(.subheadline)
                                .foregroundStyle(Color.appAccent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
        }
    }

    // MARK: - Equipment row

    private func equipmentRow(_ item: EquipmentItem) -> some View {
        let isChecked = selectedEquipment.contains(item.id)

        return Button {
            haptic.impactOccurred()
            withAnimation(.snappy(duration: 0.18)) {
                if isChecked {
                    selectedEquipment.remove(item.id)
                } else {
                    selectedEquipment.insert(item.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(isChecked ? 0.15 : 0.07))
                        .frame(width: 64, height: 64)

                    AsyncImage(url: item.imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        default:
                            Image(systemName: item.sfSymbol)
                                .font(.system(size: 22))
                                .foregroundStyle(isChecked ? Color.appAccent : .secondary)
                        }
                    }
                }
                .animation(.snappy(duration: 0.18), value: isChecked)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.appAccent : .secondary)
                    .animation(.snappy(duration: 0.18), value: isChecked)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom panel (search + CTA)

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.appBg.opacity(0), Color.appBg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 36)
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 15))
                    TextField("Search For Equipment", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))

                Button {
                    model.confirmEquipment(selectedEquipment)
                } label: {
                    HStack(spacing: 10) {
                        Text("Next")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .fontWeight(.semibold)
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.appAccent)
                .controlSize(.extraLarge)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(Color.appBg)
        }
    }
}

// MARK: - Preview

#Preview("Equipment Review — Large Gym") {
    let model = NewOnboardingFlowViewModel()
    model.gymSizeAnswer = "Large Gym"
    return ZStack {
        AppBackground()
        NewOnboardingFlow_EquipmentReviewStep(model: model)
    }
    .preferredColorScheme(.dark)
}

#Preview("Equipment Review — Garage Gym") {
    let model = NewOnboardingFlowViewModel()
    model.gymSizeAnswer = "Garage Gym"
    return ZStack {
        AppBackground()
        NewOnboardingFlow_EquipmentReviewStep(model: model)
    }
    .preferredColorScheme(.dark)
}
