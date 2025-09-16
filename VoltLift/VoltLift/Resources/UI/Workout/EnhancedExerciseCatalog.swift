import Foundation

// swiftlint:disable file_length type_body_length

// MARK: - Enhanced Exercise Catalog

/// Enhanced exercise catalog with comprehensive exercise database and metadata
enum EnhancedExerciseCatalog {
    /// All exercises in the enhanced catalog with comprehensive metadata
    static let allExercises: [Exercise] = [
        // MARK: - Chest Exercises

        Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "A fundamental upper body exercise that targets the chest, shoulders, and triceps using body weight.",
            instructions: [
                "Start in a plank position with hands shoulder-width apart",
                "Lower your body until your chest nearly touches the ground",
                "Push back up to the starting position",
                "Keep your core engaged throughout the movement"
            ],
            safetyTips: [
                "Maintain a straight line from head to heels",
                "Don't let your hips sag or pike up",
                "Control the descent - don't drop down quickly"
            ],
            targetMuscles: ["Pectoralis Major", "Anterior Deltoid", "Triceps Brachii"],
            secondaryMuscles: ["Core", "Serratus Anterior"],
            difficulty: .beginner,
            variations: [
                ExerciseVariation(
                    name: "Knee Push-up",
                    description: "Easier variation performed on knees",
                    difficultyModifier: -1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                ),
                ExerciseVariation(
                    name: "Diamond Push-up",
                    description: "Hands form diamond shape for increased triceps focus",
                    difficultyModifier: 1,
                    sfSymbolName: "diamond"
                )
            ],
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Dumbbell Bench Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"],
            description: "A classic chest exercise using dumbbells on a bench for maximum chest development.",
            instructions: [
                "Lie on bench with dumbbells in each hand",
                "Start with arms extended above chest",
                "Lower dumbbells to chest level with control",
                "Press back up to starting position"
            ],
            safetyTips: [
                "Keep feet flat on the floor",
                "Maintain natural arch in lower back",
                "Don't bounce weights off chest"
            ],
            targetMuscles: ["Pectoralis Major", "Anterior Deltoid", "Triceps Brachii"],
            secondaryMuscles: ["Serratus Anterior"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Incline Dumbbell Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"],
            description: "Targets the upper portion of the chest with an inclined bench angle.",
            instructions: [
                "Set bench to 30-45 degree incline",
                "Lie back with dumbbells in each hand",
                "Press dumbbells up and slightly together",
                "Lower with control to chest level"
            ],
            safetyTips: [
                "Don't set incline too steep (over 45 degrees)",
                "Keep shoulder blades pulled back",
                "Control the weight throughout the movement"
            ],
            targetMuscles: ["Upper Pectoralis Major", "Anterior Deltoid"],
            secondaryMuscles: ["Triceps Brachii", "Serratus Anterior"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Band Chest Press",
            muscleGroup: .chest,
            requiredEquipment: ["Resistance Bands"],
            description: "Chest exercise using resistance bands for constant tension throughout the movement.",
            instructions: [
                "Anchor band at chest height behind you",
                "Hold handles with arms extended forward",
                "Press forward bringing hands together",
                "Return to starting position with control"
            ],
            safetyTips: [
                "Ensure band is securely anchored",
                "Check band for wear before use",
                "Don't let band snap back uncontrolled"
            ],
            targetMuscles: ["Pectoralis Major", "Anterior Deltoid"],
            secondaryMuscles: ["Triceps Brachii", "Core"],
            difficulty: .beginner,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        // MARK: - Back Exercises

        Exercise(
            name: "Bent-over Row (Dumbbell)",
            muscleGroup: .back,
            requiredEquipment: ["Dumbbells"],
            description: "A compound pulling exercise that targets the middle back and rear deltoids.",
            instructions: [
                "Hold dumbbells with feet hip-width apart",
                "Hinge at hips, keeping back straight",
                "Pull dumbbells to lower ribs",
                "Squeeze shoulder blades together at top"
            ],
            safetyTips: [
                "Keep knees slightly bent",
                "Don't round your back",
                "Start with lighter weight to master form"
            ],
            targetMuscles: ["Latissimus Dorsi", "Rhomboids", "Middle Trapezius"],
            secondaryMuscles: ["Posterior Deltoid", "Biceps", "Core"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Bent-over Row (Barbell)",
            muscleGroup: .back,
            requiredEquipment: ["Barbell", "Weight Plates"],
            description: "Classic barbell rowing exercise for building back thickness and strength.",
            instructions: [
                "Stand with feet hip-width apart, holding barbell",
                "Hinge at hips with slight knee bend",
                "Pull barbell to lower chest/upper abdomen",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Keep chest up and shoulders back",
                "Don't use momentum to lift the weight",
                "Maintain neutral spine throughout"
            ],
            targetMuscles: ["Latissimus Dorsi", "Rhomboids", "Middle Trapezius"],
            secondaryMuscles: ["Posterior Deltoid", "Biceps", "Core"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Pull-up",
            muscleGroup: .back,
            requiredEquipment: ["Pull-up Bar"],
            description: "Bodyweight pulling exercise that builds upper body strength and back width.",
            instructions: [
                "Hang from bar with hands slightly wider than shoulders",
                "Pull body up until chin clears the bar",
                "Lower with control to full arm extension",
                "Repeat for desired repetitions"
            ],
            safetyTips: [
                "Don't swing or use momentum",
                "Full range of motion is important",
                "Build up gradually if you're a beginner"
            ],
            targetMuscles: ["Latissimus Dorsi", "Rhomboids", "Middle Trapezius"],
            secondaryMuscles: ["Biceps", "Posterior Deltoid", "Core"],
            difficulty: .advanced,
            variations: [
                ExerciseVariation(
                    name: "Assisted Pull-up",
                    description: "Use resistance band or machine assistance",
                    difficultyModifier: -1,
                    sfSymbolName: "figure.climbing"
                ),
                ExerciseVariation(
                    name: "Chin-up",
                    description: "Underhand grip variation",
                    difficultyModifier: 0,
                    sfSymbolName: "figure.climbing"
                )
            ],
            sfSymbolName: "figure.climbing"
        ),

        Exercise(
            name: "Band Row",
            muscleGroup: .back,
            requiredEquipment: ["Resistance Bands"],
            description: "Resistance band rowing exercise for back development with constant tension.",
            instructions: [
                "Anchor band at chest height in front of you",
                "Hold handles with arms extended forward",
                "Pull handles to your ribs",
                "Squeeze shoulder blades together"
            ],
            safetyTips: [
                "Keep torso upright and stable",
                "Don't let band snap back",
                "Control both pulling and returning phases"
            ],
            targetMuscles: ["Latissimus Dorsi", "Rhomboids", "Middle Trapezius"],
            secondaryMuscles: ["Posterior Deltoid", "Biceps"],
            difficulty: .beginner,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        // MARK: - Shoulder Exercises

        Exercise(
            name: "Overhead Press (Dumbbell)",
            muscleGroup: .shoulders,
            requiredEquipment: ["Dumbbells"],
            description: "Fundamental shoulder exercise that builds overhead pressing strength and stability.",
            instructions: [
                "Stand with feet hip-width apart",
                "Hold dumbbells at shoulder height",
                "Press weights straight up overhead",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Keep core engaged throughout",
                "Don't arch your back excessively",
                "Press in straight line, not forward"
            ],
            targetMuscles: ["Anterior Deltoid", "Medial Deltoid", "Posterior Deltoid"],
            secondaryMuscles: ["Triceps Brachii", "Upper Trapezius", "Core"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Lateral Raise",
            muscleGroup: .shoulders,
            requiredEquipment: ["Dumbbells"],
            description: "Isolation exercise targeting the medial deltoids for shoulder width development.",
            instructions: [
                "Stand with dumbbells at your sides",
                "Raise arms out to sides until parallel to floor",
                "Hold briefly at the top",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Use lighter weight than you think",
                "Don't swing the weights up",
                "Keep slight bend in elbows"
            ],
            targetMuscles: ["Medial Deltoid"],
            secondaryMuscles: ["Anterior Deltoid", "Posterior Deltoid", "Upper Trapezius"],
            difficulty: .beginner,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Band Shoulder Press",
            muscleGroup: .shoulders,
            requiredEquipment: ["Resistance Bands"],
            description: "Overhead pressing exercise using resistance bands for variable resistance.",
            instructions: [
                "Stand on band with feet hip-width apart",
                "Hold handles at shoulder height",
                "Press handles straight up overhead",
                "Lower with control against band resistance"
            ],
            safetyTips: [
                "Ensure band is securely under feet",
                "Keep core tight throughout movement",
                "Don't let band snap back uncontrolled"
            ],
            targetMuscles: ["Anterior Deltoid", "Medial Deltoid"],
            secondaryMuscles: ["Triceps Brachii", "Upper Trapezius", "Core"],
            difficulty: .beginner,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        // MARK: - Arm Exercises

        Exercise(
            name: "Biceps Curl",
            muscleGroup: .arms,
            requiredEquipment: ["Dumbbells"],
            description: "Classic isolation exercise for biceps development and arm strength.",
            instructions: [
                "Stand with dumbbells at your sides",
                "Keep elbows close to your body",
                "Curl weights up to shoulder level",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Don't swing the weights",
                "Keep wrists straight and strong",
                "Control both up and down phases"
            ],
            targetMuscles: ["Biceps Brachii", "Brachialis"],
            secondaryMuscles: ["Brachioradialis", "Anterior Deltoid"],
            difficulty: .beginner,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Triceps Extension (Band)",
            muscleGroup: .arms,
            requiredEquipment: ["Resistance Bands"],
            description: "Triceps isolation exercise using resistance bands for constant tension.",
            instructions: [
                "Anchor band overhead behind you",
                "Hold handle with both hands behind head",
                "Extend arms straight up overhead",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Keep elbows pointing forward",
                "Don't let elbows flare out to sides",
                "Control the band throughout movement"
            ],
            targetMuscles: ["Triceps Brachii"],
            secondaryMuscles: ["Posterior Deltoid", "Core"],
            difficulty: .beginner,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        Exercise(
            name: "Triceps Dip",
            muscleGroup: .arms,
            requiredEquipment: ["Adjustable Bench"],
            description: "Bodyweight exercise targeting triceps using a bench for support.",
            instructions: [
                "Sit on edge of bench with hands beside hips",
                "Slide forward off bench, supporting weight on arms",
                "Lower body by bending elbows",
                "Push back up to starting position"
            ],
            safetyTips: [
                "Keep elbows pointing back, not out",
                "Don't go too low if you feel shoulder strain",
                "Keep feet flat on floor for stability"
            ],
            targetMuscles: ["Triceps Brachii"],
            secondaryMuscles: ["Anterior Deltoid", "Pectoralis Major"],
            difficulty: .intermediate,
            variations: [
                ExerciseVariation(
                    name: "Feet Elevated Dip",
                    description: "Place feet on another bench for increased difficulty",
                    difficultyModifier: 1,
                    sfSymbolName: "rectangle.portrait"
                )
            ],
            sfSymbolName: "rectangle.portrait"
        ),

        // MARK: - Leg Exercises

        Exercise(
            name: "Bodyweight Squat",
            muscleGroup: .legs,
            requiredEquipment: [],
            description: "Fundamental lower body exercise using bodyweight for leg and glute development.",
            instructions: [
                "Stand with feet shoulder-width apart",
                "Lower body as if sitting back into a chair",
                "Keep chest up and knees tracking over toes",
                "Return to standing position"
            ],
            safetyTips: [
                "Don't let knees cave inward",
                "Keep weight on heels and mid-foot",
                "Don't round your back"
            ],
            targetMuscles: ["Quadriceps", "Gluteus Maximus", "Hamstrings"],
            secondaryMuscles: ["Calves", "Core", "Hip Flexors"],
            difficulty: .beginner,
            variations: [
                ExerciseVariation(
                    name: "Jump Squat",
                    description: "Add explosive jump at the top",
                    difficultyModifier: 1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                ),
                ExerciseVariation(
                    name: "Pulse Squat",
                    description: "Small pulses at bottom of squat",
                    difficultyModifier: 1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                )
            ],
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Goblet Squat",
            muscleGroup: .legs,
            requiredEquipment: ["Dumbbells"],
            description: "Squat variation holding a dumbbell at chest level for added resistance and core engagement.",
            instructions: [
                "Hold dumbbell vertically at chest level",
                "Stand with feet slightly wider than shoulders",
                "Squat down keeping chest up and elbows inside knees",
                "Drive through heels to return to standing"
            ],
            safetyTips: [
                "Keep the weight close to your body",
                "Don't let elbows rest on knees",
                "Maintain upright torso throughout"
            ],
            targetMuscles: ["Quadriceps", "Gluteus Maximus", "Hamstrings"],
            secondaryMuscles: ["Core", "Upper Back", "Shoulders"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Kettlebell Deadlift",
            muscleGroup: .legs,
            requiredEquipment: ["Kettlebell"],
            description: "Hip hinge movement pattern using kettlebell to target posterior chain muscles.",
            instructions: [
                "Stand with kettlebell between feet",
                "Hinge at hips and grab kettlebell handle",
                "Drive through heels and extend hips to stand",
                "Lower kettlebell with control by hinging at hips"
            ],
            safetyTips: [
                "Keep back straight throughout movement",
                "Don't round shoulders forward",
                "Lead with hips, not knees"
            ],
            targetMuscles: ["Hamstrings", "Gluteus Maximus", "Erector Spinae"],
            secondaryMuscles: ["Quadriceps", "Upper Back", "Core"],
            difficulty: .intermediate,
            sfSymbolName: "circle"
        ),

        Exercise(
            name: "Lunge (Dumbbell)",
            muscleGroup: .legs,
            requiredEquipment: ["Dumbbells"],
            description: "Unilateral leg exercise with dumbbells for balanced leg development and stability.",
            instructions: [
                "Hold dumbbells at your sides",
                "Step forward into lunge position",
                "Lower back knee toward ground",
                "Push off front foot to return to starting position"
            ],
            safetyTips: [
                "Keep front knee over ankle, not past toes",
                "Don't let front knee cave inward",
                "Keep torso upright throughout movement"
            ],
            targetMuscles: ["Quadriceps", "Gluteus Maximus", "Hamstrings"],
            secondaryMuscles: ["Calves", "Core", "Hip Flexors"],
            difficulty: .intermediate,
            variations: [
                ExerciseVariation(
                    name: "Reverse Lunge",
                    description: "Step backward instead of forward",
                    difficultyModifier: -1,
                    sfSymbolName: "dumbbell"
                ),
                ExerciseVariation(
                    name: "Walking Lunge",
                    description: "Alternate legs while moving forward",
                    difficultyModifier: 1,
                    sfSymbolName: "dumbbell"
                )
            ],
            sfSymbolName: "dumbbell"
        ),

        // MARK: - Core Exercises

        Exercise(
            name: "Plank",
            muscleGroup: .core,
            requiredEquipment: [],
            description: "Isometric core exercise that builds stability and endurance in the entire core region.",
            instructions: [
                "Start in push-up position on forearms",
                "Keep body in straight line from head to heels",
                "Engage core and hold position",
                "Breathe normally while maintaining position"
            ],
            safetyTips: [
                "Don't let hips sag or pike up",
                "Keep neck in neutral position",
                "Start with shorter holds and build up"
            ],
            targetMuscles: ["Rectus Abdominis", "Transverse Abdominis", "Obliques"],
            secondaryMuscles: ["Shoulders", "Glutes", "Back"],
            difficulty: .beginner,
            variations: [
                ExerciseVariation(
                    name: "Side Plank",
                    description: "Plank on one side targeting obliques",
                    difficultyModifier: 1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                ),
                ExerciseVariation(
                    name: "Plank Up-Down",
                    description: "Move from forearm to high plank position",
                    difficultyModifier: 1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                )
            ],
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Russian Twist",
            muscleGroup: .core,
            requiredEquipment: ["Dumbbells"],
            description: "Rotational core exercise targeting obliques and improving rotational strength.",
            instructions: [
                "Sit with knees bent, holding dumbbell",
                "Lean back slightly, lifting feet off ground",
                "Rotate torso side to side, touching weight to ground",
                "Keep chest up and core engaged"
            ],
            safetyTips: [
                "Don't round your back excessively",
                "Control the rotation, don't use momentum",
                "Keep feet off ground for added challenge"
            ],
            targetMuscles: ["Obliques", "Rectus Abdominis"],
            secondaryMuscles: ["Hip Flexors", "Shoulders"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Dead Bug",
            muscleGroup: .core,
            requiredEquipment: [],
            description: "Core stability exercise that teaches proper core engagement and coordination.",
            instructions: [
                "Lie on back with arms extended toward ceiling",
                "Bring knees to 90-degree angle",
                "Slowly extend opposite arm and leg",
                "Return to starting position and repeat other side"
            ],
            safetyTips: [
                "Keep lower back pressed to floor",
                "Move slowly and with control",
                "Don't hold your breath"
            ],
            targetMuscles: ["Transverse Abdominis", "Rectus Abdominis"],
            secondaryMuscles: ["Hip Flexors", "Shoulders"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        // MARK: - Full Body Exercises

        Exercise(
            name: "Burpee",
            muscleGroup: .fullBody,
            requiredEquipment: [],
            description: "High-intensity full-body exercise combining squat, plank, push-up, and jump movements.",
            instructions: [
                "Start standing, then squat down and place hands on floor",
                "Jump feet back into plank position",
                "Perform push-up (optional)",
                "Jump feet back to squat, then jump up with arms overhead"
            ],
            safetyTips: [
                "Land softly on jumps",
                "Modify by stepping instead of jumping",
                "Maintain good form even when tired"
            ],
            targetMuscles: ["Full Body"],
            secondaryMuscles: ["Cardiovascular System"],
            difficulty: .advanced,
            variations: [
                ExerciseVariation(
                    name: "Half Burpee",
                    description: "Eliminate the push-up portion",
                    difficultyModifier: -1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                ),
                ExerciseVariation(
                    name: "Burpee Box Jump",
                    description: "Jump onto box instead of straight up",
                    difficultyModifier: 1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                )
            ],
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Kettlebell Swing",
            muscleGroup: .fullBody,
            requiredEquipment: ["Kettlebell"],
            description: "Dynamic full-body exercise emphasizing hip hinge movement and explosive power.",
            instructions: [
                "Stand with feet wider than shoulders, kettlebell in front",
                "Hinge at hips and grab kettlebell with both hands",
                "Swing kettlebell up to chest height using hip drive",
                "Let kettlebell swing back down between legs"
            ],
            safetyTips: [
                "Power comes from hips, not arms",
                "Keep back straight throughout movement",
                "Don't let kettlebell go higher than chest"
            ],
            targetMuscles: ["Hamstrings", "Glutes", "Core", "Shoulders"],
            secondaryMuscles: ["Quadriceps", "Upper Back", "Cardiovascular System"],
            difficulty: .intermediate,
            sfSymbolName: "circle"
        ),

        // MARK: - Additional Chest Exercises

        Exercise(
            name: "Chest Fly (Dumbbell)",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"],
            description: "Isolation exercise targeting chest muscles with a wide arc motion for muscle stretch.",
            instructions: [
                "Lie on bench with dumbbells extended above chest",
                "Lower weights in wide arc until chest stretch is felt",
                "Bring weights back together above chest",
                "Keep slight bend in elbows throughout"
            ],
            safetyTips: [
                "Don't go too low and risk shoulder injury",
                "Use lighter weight than pressing exercises",
                "Control the weight throughout the movement"
            ],
            targetMuscles: ["Pectoralis Major"],
            secondaryMuscles: ["Anterior Deltoid"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Decline Push-up",
            muscleGroup: .chest,
            requiredEquipment: ["Adjustable Bench"],
            description: "Bodyweight push-up variation with feet elevated to target upper chest.",
            instructions: [
                "Place feet on bench, hands on floor",
                "Maintain plank position with elevated feet",
                "Lower chest toward floor",
                "Push back up to starting position"
            ],
            safetyTips: [
                "Keep core engaged to prevent sagging",
                "Start with lower elevation if needed",
                "Maintain straight body line"
            ],
            targetMuscles: ["Upper Pectoralis Major", "Anterior Deltoid", "Triceps"],
            secondaryMuscles: ["Core", "Serratus Anterior"],
            difficulty: .intermediate,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Wall Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Beginner-friendly bodyweight chest exercise performed against a wall.",
            instructions: [
                "Stand arm's length from wall",
                "Place palms flat against wall at shoulder height",
                "Lean forward and push back to starting position",
                "Keep body straight throughout movement"
            ],
            safetyTips: [
                "Start close to wall for easier variation",
                "Keep feet planted firmly",
                "Progress to incline then regular push-ups"
            ],
            targetMuscles: ["Pectoralis Major", "Anterior Deltoid"],
            secondaryMuscles: ["Triceps", "Core"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        // MARK: - Additional Back Exercises

        Exercise(
            name: "Single-arm Row (Dumbbell)",
            muscleGroup: .back,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"],
            description: "Unilateral back exercise allowing focus on each side independently.",
            instructions: [
                "Place one knee and hand on bench for support",
                "Hold dumbbell in opposite hand",
                "Pull dumbbell to lower ribs",
                "Lower with control and repeat"
            ],
            safetyTips: [
                "Keep back straight and parallel to floor",
                "Don't rotate torso during movement",
                "Pull elbow back, not out to side"
            ],
            targetMuscles: ["Latissimus Dorsi", "Rhomboids", "Middle Trapezius"],
            secondaryMuscles: ["Posterior Deltoid", "Biceps"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Inverted Row",
            muscleGroup: .back,
            requiredEquipment: ["Barbell", "Squat Rack"],
            description: "Bodyweight rowing exercise using barbell in squat rack for horizontal pulling.",
            instructions: [
                "Set barbell in rack at waist height",
                "Lie under bar and grab with overhand grip",
                "Pull chest to bar keeping body straight",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Keep body in straight line",
                "Adjust bar height for difficulty",
                "Don't let hips sag"
            ],
            targetMuscles: ["Latissimus Dorsi", "Rhomboids", "Middle Trapezius"],
            secondaryMuscles: ["Posterior Deltoid", "Biceps", "Core"],
            difficulty: .intermediate,
            variations: [
                ExerciseVariation(
                    name: "Feet Elevated Inverted Row",
                    description: "Place feet on bench for increased difficulty",
                    difficultyModifier: 1,
                    sfSymbolName: "dumbbell"
                )
            ],
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Superman",
            muscleGroup: .back,
            requiredEquipment: [],
            description: "Bodyweight exercise targeting lower back and posterior chain muscles.",
            instructions: [
                "Lie face down with arms extended overhead",
                "Simultaneously lift chest, arms, and legs off ground",
                "Hold briefly at top position",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Don't lift too high and strain lower back",
                "Keep movements controlled",
                "Stop if you feel pain"
            ],
            targetMuscles: ["Erector Spinae", "Gluteus Maximus"],
            secondaryMuscles: ["Posterior Deltoid", "Hamstrings"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Face Pull (Band)",
            muscleGroup: .back,
            requiredEquipment: ["Resistance Bands"],
            description: "Rear deltoid and upper back exercise using resistance bands for posture improvement.",
            instructions: [
                "Anchor band at face height",
                "Hold handles with arms extended forward",
                "Pull handles to face, separating hands",
                "Squeeze shoulder blades together"
            ],
            safetyTips: [
                "Keep elbows high throughout movement",
                "Don't let band snap back",
                "Focus on squeezing shoulder blades"
            ],
            targetMuscles: ["Posterior Deltoid", "Rhomboids", "Middle Trapezius"],
            secondaryMuscles: ["External Rotators"],
            difficulty: .beginner,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        // MARK: - Additional Shoulder Exercises

        Exercise(
            name: "Front Raise",
            muscleGroup: .shoulders,
            requiredEquipment: ["Dumbbells"],
            description: "Isolation exercise targeting the front deltoids with forward arm elevation.",
            instructions: [
                "Stand with dumbbells at your sides",
                "Raise one or both arms forward to shoulder height",
                "Hold briefly at top",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Don't swing weights up",
                "Keep slight bend in elbows",
                "Don't raise above shoulder height"
            ],
            targetMuscles: ["Anterior Deltoid"],
            secondaryMuscles: ["Upper Pectoralis Major", "Core"],
            difficulty: .beginner,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Rear Delt Fly",
            muscleGroup: .shoulders,
            requiredEquipment: ["Dumbbells"],
            description: "Isolation exercise targeting rear deltoids for balanced shoulder development.",
            instructions: [
                "Bend forward at hips with dumbbells hanging down",
                "Raise arms out to sides in reverse fly motion",
                "Squeeze shoulder blades together at top",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Keep knees slightly bent",
                "Don't use momentum",
                "Focus on squeezing shoulder blades"
            ],
            targetMuscles: ["Posterior Deltoid"],
            secondaryMuscles: ["Rhomboids", "Middle Trapezius"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Pike Push-up",
            muscleGroup: .shoulders,
            requiredEquipment: [],
            description: "Bodyweight shoulder exercise mimicking overhead press movement pattern.",
            instructions: [
                "Start in downward dog position",
                "Walk feet closer to hands to increase angle",
                "Lower head toward ground between hands",
                "Push back up to starting position"
            ],
            safetyTips: [
                "Keep core engaged",
                "Don't go too deep initially",
                "Build up gradually"
            ],
            targetMuscles: ["Anterior Deltoid", "Medial Deltoid"],
            secondaryMuscles: ["Triceps", "Upper Trapezius", "Core"],
            difficulty: .intermediate,
            variations: [
                ExerciseVariation(
                    name: "Feet Elevated Pike Push-up",
                    description: "Place feet on bench for increased difficulty",
                    difficultyModifier: 1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                )
            ],
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Band Lateral Raise",
            muscleGroup: .shoulders,
            requiredEquipment: ["Resistance Bands"],
            description: "Lateral deltoid exercise using resistance bands for constant tension.",
            instructions: [
                "Stand on band with feet hip-width apart",
                "Hold handles at your sides",
                "Raise arms out to sides until parallel to floor",
                "Lower with control against band resistance"
            ],
            safetyTips: [
                "Keep slight bend in elbows",
                "Don't let band snap back",
                "Control both up and down phases"
            ],
            targetMuscles: ["Medial Deltoid"],
            secondaryMuscles: ["Anterior Deltoid", "Posterior Deltoid"],
            difficulty: .beginner,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        // MARK: - Additional Arm Exercises

        Exercise(
            name: "Hammer Curl",
            muscleGroup: .arms,
            requiredEquipment: ["Dumbbells"],
            description: "Biceps exercise with neutral grip targeting brachialis and brachioradialis.",
            instructions: [
                "Hold dumbbells with neutral grip (palms facing each other)",
                "Keep elbows close to body",
                "Curl weights up maintaining neutral grip",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Don't swing the weights",
                "Keep wrists straight",
                "Control the negative portion"
            ],
            targetMuscles: ["Brachialis", "Brachioradialis", "Biceps Brachii"],
            secondaryMuscles: ["Anterior Deltoid"],
            difficulty: .beginner,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Overhead Triceps Extension",
            muscleGroup: .arms,
            requiredEquipment: ["Dumbbells"],
            description: "Triceps isolation exercise with overhead arm position for full muscle stretch.",
            instructions: [
                "Hold dumbbell with both hands overhead",
                "Lower weight behind head by bending elbows",
                "Keep elbows pointing forward",
                "Extend arms back to starting position"
            ],
            safetyTips: [
                "Don't let elbows flare out",
                "Use lighter weight initially",
                "Control the weight throughout"
            ],
            targetMuscles: ["Triceps Brachii"],
            secondaryMuscles: ["Posterior Deltoid", "Core"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Close-grip Push-up",
            muscleGroup: .arms,
            requiredEquipment: [],
            description: "Bodyweight push-up variation with hands close together to emphasize triceps.",
            instructions: [
                "Start in push-up position with hands close together",
                "Form diamond or triangle shape with hands",
                "Lower body keeping elbows close to sides",
                "Push back up to starting position"
            ],
            safetyTips: [
                "Keep elbows tucked in, not flared",
                "Maintain straight body line",
                "Start with regular push-ups if too difficult"
            ],
            targetMuscles: ["Triceps Brachii"],
            secondaryMuscles: ["Pectoralis Major", "Anterior Deltoid", "Core"],
            difficulty: .intermediate,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Band Biceps Curl",
            muscleGroup: .arms,
            requiredEquipment: ["Resistance Bands"],
            description: "Biceps exercise using resistance bands for variable resistance throughout range of motion.",
            instructions: [
                "Stand on band with feet hip-width apart",
                "Hold handles with underhand grip",
                "Curl handles up to shoulder level",
                "Lower with control against band resistance"
            ],
            safetyTips: [
                "Keep elbows stationary at sides",
                "Don't let band snap back",
                "Maintain tension throughout movement"
            ],
            targetMuscles: ["Biceps Brachii", "Brachialis"],
            secondaryMuscles: ["Brachioradialis"],
            difficulty: .beginner,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        // MARK: - Additional Leg Exercises

        Exercise(
            name: "Single-leg Glute Bridge",
            muscleGroup: .legs,
            requiredEquipment: [],
            description: "Unilateral glute exercise targeting hip extension and stability.",
            instructions: [
                "Lie on back with one knee bent, other leg extended",
                "Drive through heel to lift hips up",
                "Squeeze glutes at top position",
                "Lower with control and repeat"
            ],
            safetyTips: [
                "Keep core engaged",
                "Don't arch back excessively",
                "Focus on glute activation"
            ],
            targetMuscles: ["Gluteus Maximus", "Hamstrings"],
            secondaryMuscles: ["Core", "Hip Stabilizers"],
            difficulty: .intermediate,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Calf Raise",
            muscleGroup: .legs,
            requiredEquipment: ["Dumbbells"],
            description: "Isolation exercise targeting calf muscles for lower leg development.",
            instructions: [
                "Stand with dumbbells at sides",
                "Rise up onto toes as high as possible",
                "Hold briefly at top position",
                "Lower with control to starting position"
            ],
            safetyTips: [
                "Keep knees straight but not locked",
                "Control both up and down phases",
                "Use full range of motion"
            ],
            targetMuscles: ["Gastrocnemius", "Soleus"],
            secondaryMuscles: ["Tibialis Anterior"],
            difficulty: .beginner,
            variations: [
                ExerciseVariation(
                    name: "Single-leg Calf Raise",
                    description: "Perform on one leg for increased difficulty",
                    difficultyModifier: 1,
                    sfSymbolName: "dumbbell"
                )
            ],
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Wall Sit",
            muscleGroup: .legs,
            requiredEquipment: [],
            description: "Isometric leg exercise building quadriceps endurance and mental toughness.",
            instructions: [
                "Stand with back against wall",
                "Slide down until thighs are parallel to floor",
                "Keep knees at 90-degree angle",
                "Hold position for desired time"
            ],
            safetyTips: [
                "Keep knees aligned over ankles",
                "Don't let knees cave inward",
                "Breathe normally during hold"
            ],
            targetMuscles: ["Quadriceps", "Gluteus Maximus"],
            secondaryMuscles: ["Hamstrings", "Core"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Romanian Deadlift (Dumbbell)",
            muscleGroup: .legs,
            requiredEquipment: ["Dumbbells"],
            description: "Hip hinge exercise targeting hamstrings and glutes with emphasis on eccentric control.",
            instructions: [
                "Hold dumbbells in front of thighs",
                "Hinge at hips, pushing hips back",
                "Lower weights while keeping legs relatively straight",
                "Drive hips forward to return to standing"
            ],
            safetyTips: [
                "Keep back straight throughout",
                "Don't round shoulders",
                "Feel stretch in hamstrings"
            ],
            targetMuscles: ["Hamstrings", "Gluteus Maximus"],
            secondaryMuscles: ["Erector Spinae", "Upper Back"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Step-up",
            muscleGroup: .legs,
            requiredEquipment: ["Adjustable Bench"],
            description: "Unilateral leg exercise using bench for functional movement pattern.",
            instructions: [
                "Place one foot on bench",
                "Step up by driving through heel on bench",
                "Stand tall on bench",
                "Step down with control and repeat"
            ],
            safetyTips: [
                "Use full foot on bench, not just toes",
                "Don't push off back foot",
                "Control the descent"
            ],
            targetMuscles: ["Quadriceps", "Gluteus Maximus"],
            secondaryMuscles: ["Hamstrings", "Calves", "Core"],
            difficulty: .intermediate,
            variations: [
                ExerciseVariation(
                    name: "Weighted Step-up",
                    description: "Hold dumbbells for added resistance",
                    difficultyModifier: 1,
                    sfSymbolName: "rectangle.portrait"
                )
            ],
            sfSymbolName: "rectangle.portrait"
        ),

        Exercise(
            name: "Bulgarian Split Squat",
            muscleGroup: .legs,
            requiredEquipment: ["Adjustable Bench"],
            description: "Advanced unilateral leg exercise with rear foot elevated for increased range of motion.",
            instructions: [
                "Place rear foot on bench behind you",
                "Lower into lunge position",
                "Keep most weight on front leg",
                "Drive through front heel to return up"
            ],
            safetyTips: [
                "Don't lean too far forward",
                "Keep front knee aligned over ankle",
                "Start with bodyweight only"
            ],
            targetMuscles: ["Quadriceps", "Gluteus Maximus"],
            secondaryMuscles: ["Hamstrings", "Hip Flexors", "Core"],
            difficulty: .advanced,
            sfSymbolName: "rectangle.portrait"
        ),

        // MARK: - Additional Core Exercises

        Exercise(
            name: "Mountain Climber",
            muscleGroup: .core,
            requiredEquipment: [],
            description: "Dynamic core exercise combining plank position with alternating knee drives.",
            instructions: [
                "Start in plank position",
                "Bring one knee toward chest",
                "Quickly switch legs in running motion",
                "Keep hips level and core engaged"
            ],
            safetyTips: [
                "Don't let hips pike up",
                "Keep shoulders over wrists",
                "Start slowly and build speed"
            ],
            targetMuscles: ["Rectus Abdominis", "Obliques", "Hip Flexors"],
            secondaryMuscles: ["Shoulders", "Quadriceps", "Cardiovascular System"],
            difficulty: .intermediate,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Bicycle Crunch",
            muscleGroup: .core,
            requiredEquipment: [],
            description: "Dynamic core exercise targeting obliques with alternating elbow-to-knee movement.",
            instructions: [
                "Lie on back with hands behind head",
                "Bring knees to 90-degree angle",
                "Bring opposite elbow to knee while extending other leg",
                "Alternate sides in cycling motion"
            ],
            safetyTips: [
                "Don't pull on neck",
                "Keep lower back pressed to floor",
                "Focus on rotating from core, not neck"
            ],
            targetMuscles: ["Obliques", "Rectus Abdominis"],
            secondaryMuscles: ["Hip Flexors"],
            difficulty: .intermediate,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Bird Dog",
            muscleGroup: .core,
            requiredEquipment: [],
            description: "Core stability exercise improving balance and coordination while strengthening deep core muscles.",
            instructions: [
                "Start on hands and knees",
                "Extend opposite arm and leg simultaneously",
                "Hold position while maintaining balance",
                "Return to starting position and switch sides"
            ],
            safetyTips: [
                "Keep hips level",
                "Don't arch back excessively",
                "Move slowly and with control"
            ],
            targetMuscles: ["Transverse Abdominis", "Erector Spinae"],
            secondaryMuscles: ["Glutes", "Shoulders", "Hip Stabilizers"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Hollow Body Hold",
            muscleGroup: .core,
            requiredEquipment: [],
            description: "Isometric core exercise creating full-body tension and core stability.",
            instructions: [
                "Lie on back with arms overhead",
                "Press lower back to floor and lift shoulders and legs",
                "Create banana shape with body",
                "Hold position while breathing normally"
            ],
            safetyTips: [
                "Keep lower back pressed to floor",
                "Don't hold breath",
                "Start with knees bent if too difficult"
            ],
            targetMuscles: ["Rectus Abdominis", "Transverse Abdominis"],
            secondaryMuscles: ["Hip Flexors", "Shoulders"],
            difficulty: .intermediate,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Pallof Press (Band)",
            muscleGroup: .core,
            requiredEquipment: ["Resistance Bands"],
            description: "Anti-rotation core exercise using resistance bands to challenge core stability.",
            instructions: [
                "Anchor band at chest height to your side",
                "Hold handle at chest with both hands",
                "Press handle straight out from chest",
                "Hold and resist rotation, then return to chest"
            ],
            safetyTips: [
                "Keep core braced throughout",
                "Don't let torso rotate",
                "Stand with feet hip-width apart"
            ],
            targetMuscles: ["Transverse Abdominis", "Obliques"],
            secondaryMuscles: ["Shoulders", "Hip Stabilizers"],
            difficulty: .intermediate,
            sfSymbolName: "bolt.horizontal.circle"
        ),

        // MARK: - Additional Full Body Exercises

        Exercise(
            name: "Thrusters (Dumbbell)",
            muscleGroup: .fullBody,
            requiredEquipment: ["Dumbbells"],
            description: "Compound full-body exercise combining squat and overhead press movements.",
            instructions: [
                "Hold dumbbells at shoulder height",
                "Perform squat while keeping weights at shoulders",
                "Drive up from squat and press weights overhead",
                "Lower weights to shoulders and repeat"
            ],
            safetyTips: [
                "Keep core engaged throughout",
                "Don't let knees cave inward",
                "Use legs to help drive weights up"
            ],
            targetMuscles: ["Quadriceps", "Glutes", "Shoulders", "Core"],
            secondaryMuscles: ["Hamstrings", "Triceps", "Upper Back"],
            difficulty: .advanced,
            sfSymbolName: "dumbbell"
        ),

        Exercise(
            name: "Turkish Get-up (Kettlebell)",
            muscleGroup: .fullBody,
            requiredEquipment: ["Kettlebell"],
            description: "Complex full-body movement pattern promoting stability, mobility, and strength.",
            instructions: [
                "Lie on back holding kettlebell in one hand",
                "Follow specific sequence to stand up",
                "Keep kettlebell overhead throughout movement",
                "Reverse the sequence to return to lying position"
            ],
            safetyTips: [
                "Learn the movement pattern without weight first",
                "Keep eyes on kettlebell throughout",
                "Move slowly and with control"
            ],
            targetMuscles: ["Full Body"],
            secondaryMuscles: ["Stabilizers", "Core", "Shoulders"],
            difficulty: .advanced,
            sfSymbolName: "circle"
        ),

        Exercise(
            name: "Bear Crawl",
            muscleGroup: .fullBody,
            requiredEquipment: [],
            description: "Primal movement pattern engaging entire body while improving coordination and strength.",
            instructions: [
                "Start on hands and knees",
                "Lift knees slightly off ground",
                "Crawl forward moving opposite hand and foot",
                "Keep hips low and core engaged"
            ],
            safetyTips: [
                "Keep knees close to ground",
                "Don't let hips pike up",
                "Move slowly initially to master pattern"
            ],
            targetMuscles: ["Core", "Shoulders", "Quadriceps"],
            secondaryMuscles: ["Triceps", "Hip Flexors", "Stabilizers"],
            difficulty: .intermediate,
            sfSymbolName: "figure.strengthtraining.traditional"
        ),

        Exercise(
            name: "Renegade Row",
            muscleGroup: .fullBody,
            requiredEquipment: ["Dumbbells"],
            description: "Combination plank and rowing exercise challenging core stability and back strength.",
            instructions: [
                "Start in plank position holding dumbbells",
                "Row one dumbbell to ribs while maintaining plank",
                "Lower weight with control",
                "Alternate arms while keeping hips stable"
            ],
            safetyTips: [
                "Don't let hips rotate",
                "Keep core braced throughout",
                "Use lighter weights than regular rows"
            ],
            targetMuscles: ["Latissimus Dorsi", "Core", "Shoulders"],
            secondaryMuscles: ["Rhomboids", "Biceps", "Stabilizers"],
            difficulty: .advanced,
            sfSymbolName: "dumbbell"
        )
    ]
}

// swiftlint:enable file_length type_body_length
