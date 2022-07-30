# @version >=0.3.3

# The prime q in the base field F_q for G1 
BASE_MODULUS : constant(uint256) = 21888242871839275222246405745257275088696311157297823662689037894645226208583

# The prime moludus of the scalar field of G1.
SCALAR_MODULUS : constant(uint256) = 21888242871839275222246405745257275088548364400416034343698204186575808495617

# the number of inputs
N_INPUTS: constant(uint256) = 1 

struct G1Point:
    X: uint256
    Y: uint256

# Encoding of field elements is: X[0] * z + X[1]
struct G2Point:
    X: uint256[2]
    Y: uint256[2]


struct VerifyingKey:
    alfa1: G1Point
    beta2: G2Point
    gamma2: G2Point
    delta2: G2Point
    IC: DynArray[G1Point, 2]


struct Proof:
    A: G1Point
    B: G2Point
    C: G1Point


# @dev return the generator of G1
@internal
def P1() -> G1Point:
    return G1Point({X: 1, Y: 2})


# @dev return the generator of G2
@internal
def P2() -> G2Point:
    return G2Point({
        X: [
          11559732032986387107991004021392285783925812861821192530917403151452391805634,
          10857046999023057135944570762232829481370756359578518086990519993285655852781
        ],
        Y: [
          4082367875863433681332203403145435568316851327593401208105741076214120093531,
          8495653923123431417604973247489272438418190587263600148770280649306958101930
        ]}
      )


# @dev return r the negation of p, i.e. p.addition(p.negate()) should be zero.
@internal
def negate(p: G1Point) -> G1Point:
    if (p.X == 0) and (p.Y == 0):
        return G1Point({X: 0, Y: 0})

    # Validate input or revert
    #assert ((p.X < BASE_MODULUS) and (p.Y < BASE_MODULUS)), "invalid proof"

    # We know p.Y > 0 and p.Y < BASE_MODULUS.
    return G1Point({X: p.X, Y: BASE_MODULUS - p.Y})


# @dev return r the sum of two points of [email protected] r the sum of two points of G1
@internal
def addition(p1: G1Point, p2: G1Point) -> G1Point:
    # By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
    # on the curve.
    a: uint256[2] = [p1.X, p1.Y]
    b: uint256[2] = [p2.X, p2.Y]
    result : uint256[2] = ecadd(a, b)
    r : G1Point = G1Point({X: result[0], Y: result[1]})
    return r


# @dev return r the product of a point on G1 and a scalar, i.e.
#      p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
@internal
def scalar_mul(p: G1Point, s: uint256) -> G1Point:
    a: uint256[2] = [p.X, p.Y]
    result: uint256[2] = ecmul(a, s)
    r: G1Point = G1Point({X: result[0], Y: result[1]})
    return r


# @dev Asserts the pairing check
#      e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
#      For example pairing([P1(), P1().negate()], [P2(), P2()]) should succeed
#      this function supports n=N_INPUTS maximum
@internal
def pairing_check(p1 : DynArray[G1Point, 4], p2: DynArray[G2Point, 4]) -> bool:
    # By EIP-197 all input is verified to be less than the BASE_MODULUS and form elements in their
    # respective groups of the right order.

    #assert len(p1) != len(p2), "invalid proof"

    input: DynArray[uint256, 24] = []
    for i in range(24): 
      input[i * 6 + 0] = p1[i].X
      input[i * 6 + 1] = p1[i].Y
      input[i * 6 + 2] = p2[i].X[0]
      input[i * 6 + 3] = p2[i].X[1]
      input[i * 6 + 4] = p2[i].Y[0]
      input[i * 6 + 5] = p2[i].Y[1]
    
    success: Bytes[32] = b"0"

    # raw_call to ecpairing contract
    success = raw_call(0x0000000000000000000000000000000000000008, _abi_encode(input), max_outsize=32, is_static_call=True)
    
    return success != b"0"

# @dev compute verifying key
@internal
def verifying_key() -> VerifyingKey:
    vk: VerifyingKey = VerifyingKey(
        {
            alfa1: G1Point({X: 3016211889281681738095294780317378561285424153613180917925396708047979345495, Y: 20264523281898116934930506124543478382488861025004626593115979146206709108009}),
            beta2: G2Point({X: [157930666587747345452957849720644747572300920958897158679909509811613719765, 20348450435295063177941634803839488945012784404602458313340134761495694788240], Y: [1257242928635386139344773665796498199582445015569741434073159952057940009328, 21655591834642316259287259258033370908245892477242940351800697921127350446787]}), 
            gamma2: G2Point({X: [11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781], Y: [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]}),
            delta2: G2Point({X: [1950851895037639703858819432182968089920483131628389079008026090520730986887, 7762352691574900395541661186758685787166034850921723347032361074639107434488], Y: [3062022387828966619183401922682946011503239933574860021807618621588907150179, 4768191327347274557057476985630633492524813088773655827150143977439966878209]}),  
            IC: []
        }
    )

    
    vk.IC[0] = G1Point({X: 8830683060132947807038903827029042786413412943948723320166646791312327345309, Y: 13103681011155607383329312229241610477523763929906347413258328977561501632484})
    
    vk.IC[1] = G1Point({X: 6142212746052095252874414148347556113402584755921620425506014323913930333914, Y: 10701177280113114829349794978119097872717090474482653015881636435508497698102})
    
    return vk


# @dev Verifies the proof
@external
def verify_proof(a: uint256[2], b: uint256[2][2], c: uint256[2], input: DynArray[uint256, N_INPUTS]) -> bool:
    # If the values are not in the correct range, the Pairing contract will revert.
    proof: Proof = Proof({
        A: G1Point({X: a[0], Y: a[1]}),
        B: G2Point({X: [b[0][0], b[0][1]], Y: [b[1][0], b[1][1]]}),
        C: G1Point({X: c[0], Y: c[1]})
    })

    vk: VerifyingKey = self.verifying_key()

    # Compute the linear combination vk_x of inputs times IC
    # assert len(input) + 1 == len(vk.IC), "invalid proof"
    vk_x: G1Point = vk.IC[0]

    if N_INPUTS > 1:
        for i in range(N_INPUTS):
            vk_x = self.addition(vk_x, self.scalar_mul(vk.IC[i+1], input[i]))
    else:
        vk_x = self.addition(vk_x, self.scalar_mul(vk.IC[1], input[0]))

    # check pairing
    p1: DynArray[G1Point, 4] = [
        self.negate(proof.A),
        vk.alfa1,
        vk_x,
        proof.C
    ]
    p2: DynArray[G2Point, 4] = [
        proof.B,
        vk.beta2,
        vk.gamma2,
        vk.delta2
    ]

    return self.pairing_check(p1, p2)

@external
def a() -> uint256:
    return 2