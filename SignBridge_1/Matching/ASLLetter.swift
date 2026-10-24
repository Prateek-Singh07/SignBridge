//
//  ASLLetter.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import Foundation

/// Represents the alphabet letters available in the practice experience (A-Z).
/// Note: Language context is strictly sign language alphabet.
enum ASLLetter: String, CaseIterable, Identifiable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case h = "H"
    case i = "I"
    case j = "J"
    case k = "K"
    case l = "L"
    case m = "M"
    case n = "N"
    case o = "O"
    case p = "P"
    case q = "Q"
    case r = "R"
    case s = "S"
    case t = "T"
    case u = "U"
    case v = "V"
    case w = "W"
    case x = "X"
    case y = "Y"
    case z = "Z"

    var id: String { rawValue }
    var name: String { rawValue }

    func lowercased() -> String {
        rawValue.lowercased()
    }

    /// Practice instruction for each letter handshape.
    var instruction: String {
        switch self {
        case .a:
            return "Make a fist with your four fingers curled into the palm and your thumb resting upright against the side of your index finger."
        case .b:
            return "Fingers straight up and together, thumb folded across the palm."
        case .c:
            return "Curve your hand and fingers to form an open 'C' shape facing sideways."
        case .d:
            return "Point your index finger straight up, while your thumb touches the tips of your middle, ring, and pinky fingers."
        case .e:
            return "Curl all four fingers down with your fingertips resting against your thumb folded across the bottom."
        case .f:
            return "Touch the tips of your index finger and thumb together in a circle, keeping your remaining three fingers extended straight up."
        case .g:
            return "Extend your index finger and thumb horizontally parallel to each other, curling your other three fingers into your palm."
        case .h:
            return "Extend your index and middle fingers straight out horizontally together, with your thumb folded over your ring finger."
        case .i:
            return "Little finger up, other fingers curled, thumb across them."
        case .j:
            return "Extend your little finger and trace the shape of the letter 'J' in the air with a downward and curved hook motion."
        case .k:
            return "Extend your index finger up and middle finger forward at an angle, with your thumb pressed against the base of your middle finger."
        case .l:
            return "Index finger up, thumb out to the side, other fingers curled."
        case .m:
            return "Tuck your thumb under your first three fingers (index, middle, ring), folding them over your thumb into a fist."
        case .n:
            return "Tuck your thumb under your first two fingers (index, middle), folding them over your thumb into a fist."
        case .o:
            return "Curve all of your fingers and thumb to meet at their tips, forming a round 'O' shape."
        case .p:
            return "Form the 'K' handshape with your index, middle, and thumb, and point the handshape downward."
        case .q:
            return "Form the 'G' handshape with your index finger and thumb, and point both downward towards the ground."
        case .r:
            return "Cross your middle finger over the back of your index finger, keeping both upright while curling the remaining fingers."
        case .s:
            return "Make a tight fist and wrap your thumb firmly across the front of all your curled fingers."
        case .t:
            return "Make a fist with your thumb tucked between your index and middle fingers, poking out slightly."
        case .u:
            return "Extend your index and middle fingers straight up and held tightly together, with other fingers curled and held by your thumb."
        case .v:
            return "Index and middle fingers up and spread apart, others curled with the thumb holding them down."
        case .w:
            return "Index, middle, and ring fingers up and spread, thumb holding the little finger down."
        case .x:
            return "Make a fist and raise your index finger bent into a curved hook shape."
        case .y:
            return "Thumb and little finger extended, other three fingers curled."
        case .z:
            return "Extend your index finger and trace the letter 'Z' in the air with three quick zigzag strokes."
        }
    }

    /// Explicit per-letter recognition support status.
    /// Extended-finger-set letters (B, W, V, I) have deterministic geometric rules.
    /// Other letters remain unsupported until full pose rules are physically validated.
    var isRecognitionSupported: Bool {
        return true
    }
}
