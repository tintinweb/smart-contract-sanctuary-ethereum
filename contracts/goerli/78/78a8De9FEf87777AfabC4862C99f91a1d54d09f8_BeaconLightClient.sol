// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.14;

import "./libraries/Pairing.sol";

contract BLSAggregatedSignatureVerifier {

    struct SignatureVerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct SignatureProof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function signatureVerifyingKey() internal pure returns (SignatureVerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
            6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
            10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
            10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
            8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [11189806570539144736727012544656298041306137206388952077894435495341338625055,
            11858349594271760113337524322538902608009287667177178391464696310726879422067],
            [5595369512531394865406589446247079617010140216284237311327337258440181370157,
            18379371339796698120587917695047371560944479696904810575900438613279013654931]
        );
        vk.IC = new Pairing.G1Point[](35);

        vk.IC[0] = Pairing.G1Point(
            13438283153526239070838379159409825246703895230089526840814483072314913977983,
            16291730063905947425018400876105600537656457924790842220052692081289028256794
        );

        vk.IC[1] = Pairing.G1Point(
            1429938886066451034867026739198324202949956272687375478141651682569332075686,
            18806431884851308549797181858759261879020736928779385772720677127115677612462
        );

        vk.IC[2] = Pairing.G1Point(
            8335067696037666326793259821997699668324318011973475989945872747912505606957,
            13189566974829609492092448936972497141172587818722894443032826226520409729394
        );

        vk.IC[3] = Pairing.G1Point(
            21213708715712156866767777661977788277850580126695070238930328258638542993703,
            3877107115173683946579082727455205426400698917801428419580663904962445718889
        );

        vk.IC[4] = Pairing.G1Point(
            3748525012097900874070569260703250685904702680344177064892453012802172504741,
            8423811644339028185871468942997655026053600144354475441223034246188534241172
        );

        vk.IC[5] = Pairing.G1Point(
            11134530744751908086526008153074565319580828785779188828267782220600326743165,
            375912472296333214747479910788640389038161644029402170222317276851277282317
        );

        vk.IC[6] = Pairing.G1Point(
            18669683155676314400736103482876735832539064992855833590512079820697376832625,
            4147504453824255433256747426179685953315806543485215419388538515006411543511
        );

        vk.IC[7] = Pairing.G1Point(
            385560172380008767403272684055202310596864189235556057994215397687696080687,
            14596963844930874224691668769598658775310112038775643916321202991409712142374
        );

        vk.IC[8] = Pairing.G1Point(
            6471994225246937839694659547442669205729903722746005219843833567205280055155,
            1938045789275182618453800876789094859670398628923034252392072052577483681201
        );

        vk.IC[9] = Pairing.G1Point(
            20632000976241748017252057302421816585868281357537787775488144723478439549363,
            2445549694658321028124709883460204776759445020192364705136288061119923723738
        );

        vk.IC[10] = Pairing.G1Point(
            12766002908804030335033465302685342331816209010088333403688149114528965187214,
            14643685459236117538698635600410748469362688017818749468665639541159106461656
        );

        vk.IC[11] = Pairing.G1Point(
            20510048680791036740343627536284187728093468973039622995626194918504203711795,
            3270566863451302875472140807536509669207686686099815110074541975682238607424
        );

        vk.IC[12] = Pairing.G1Point(
            6600047304611185168169711529286102926727944673037538316136850542624164821160,
            14134230986748798202313617761637363125569948747861148801694949096977458868689
        );

        vk.IC[13] = Pairing.G1Point(
            19137996326497674907448424956747478578202778141546092035923958470352908229306,
            7984881466165223479027016481879920210277603709893792979055269407896152203253
        );

        vk.IC[14] = Pairing.G1Point(
            3481005874936573398374355492482181758981604007810877980206018229962661049205,
            981855150305594898224303660493365197253179914591639965076720150519984515269
        );

        vk.IC[15] = Pairing.G1Point(
            5198296937595783791864043076511066537316578343982812042120096654675668384796,
            1601279314402043168663040611139912304824589654515366478528124066492339865615
        );

        vk.IC[16] = Pairing.G1Point(
            8435958390020321687643099843717868117166967946921853822325139793002642462991,
            12328845416666837352080944330965640256157392591367801717452437326455143244820
        );

        vk.IC[17] = Pairing.G1Point(
            1012873840560905838578101386733145027952537294190702800696473854363011450622,
            13580006103452593788028871241714684846684820306297855652500655477991793836041
        );

        vk.IC[18] = Pairing.G1Point(
            4622684255372187521742007079114922515583326639671053144311130165601369069664,
            18950241556985359291473619032709273432443744870639240933077513772456732543484
        );

        vk.IC[19] = Pairing.G1Point(
            9322075717259048284144778010920463844962481572617680198969724873538545361742,
            1880065465685632668492093361238089726144071476289572804927527407881937990593
        );

        vk.IC[20] = Pairing.G1Point(
            4330704200057784984285238214760883322844698255146289754222975690959301938577,
            15568086689515796515319925875897634670707557693612654353192891764065028103095
        );

        vk.IC[21] = Pairing.G1Point(
            19702540893444333366775736781263373022749931959028694012791557423906262275531,
            20923463306275493047126320035047308602454191366815719864754220198907557550389
        );

        vk.IC[22] = Pairing.G1Point(
            5164667925583093544290844216735865871934833902020774988551159085155399786933,
            8226906020821293167132937027133777514225796523947055106538977547929993519050
        );

        vk.IC[23] = Pairing.G1Point(
            4684946447217829235489329481344881896066793957260069471436653198703003520254,
            9314190281160828770684229897354263955996548157175479271225490407999943684083
        );

        vk.IC[24] = Pairing.G1Point(
            12639483548511544767889481687232770012815858827021854229165122838439958698629,
            15890219997674598896408548173709679845432409882105194910691064212828711043985
        );

        vk.IC[25] = Pairing.G1Point(
            5131762414318912377517137526263328936082157367606573522194702864126319599373,
            8268345239020503668646787572241336087246492377391409096001840149454837125597
        );

        vk.IC[26] = Pairing.G1Point(
            18745415518447345683284721721581075349487649803655018712435473533410711535662,
            19908623832126320812366522922570102666173034198560749957596788947314071410085
        );

        vk.IC[27] = Pairing.G1Point(
            16807457275996067784364229174559204140840267946974692152522840791692650160265,
            18203483002801341910607430118104165779220737084213934937475995623473273959231
        );

        vk.IC[28] = Pairing.G1Point(
            8766709093497184166465308574903409264050435764685505650430880139237530206382,
            20675232749756979969493091641140086530918252654337378789443379415126511290827
        );

        vk.IC[29] = Pairing.G1Point(
            8942849026430713071891495679490265548212054361060361315477025317593612672691,
            1292286646422842030272398204363620203639822982358370843747671903215698914929
        );

        vk.IC[30] = Pairing.G1Point(
            2991478625949020518389154427348603511919270126792597800473000635640481885251,
            1730668326601810681136337092203764687763374756087832222233636705359386180907
        );

        vk.IC[31] = Pairing.G1Point(
            7933328460212850679300065376071217385811034880997511075544182323497475900718,
            5480214634558732585651558840829582633059652218936911468051350946073934282939
        );

        vk.IC[32] = Pairing.G1Point(
            5694705432093390774585763839149140327253976577768041279313620017377095200584,
            4780464564707006736800977063708732892012691534428604350370469730117042561612
        );

        vk.IC[33] = Pairing.G1Point(
            1858098361574168452341506620057746224977357949233359564065723900189497861160,
            20266189774664741870774971270155299605278185006897626472067814285550646131004
        );

        vk.IC[34] = Pairing.G1Point(
            2002668352095941445583604079204410504943596366638463056940905924870814229723,
            13406916168642651648493192962582752162175433734225557219247584661868589311576
        );

    }
    function verifySignature(uint[] memory input, SignatureProof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        SignatureVerifyingKey memory vk = signatureVerifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifySignatureProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[34] memory input
    ) public view returns (bool r) {
        SignatureProof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verifySignature(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

import "./Structs.sol";
import "./BLSAggregatedSignatureVerifier.sol";
import "./PoseidonCommitmentVerifier.sol";
import "./libraries/SimpleSerialize.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

uint256 constant OPTIMISTIC_UPDATE_TIMEOUT = 86400;
uint256 constant SLOTS_PER_EPOCH = 32;
uint256 constant SLOTS_PER_SYNC_COMMITTEE_PERIOD = 8192;
uint256 constant MIN_SYNC_COMMITTEE_PARTICIPANTS = 10;
uint256 constant SYNC_COMMITTEE_SIZE = 512;
uint256 constant FINALIZED_ROOT_INDEX = 105;
uint256 constant NEXT_SYNC_COMMITTEE_INDEX = 55;
uint256 constant EXECUTION_STATE_ROOT_INDEX = 402;

contract BeaconLightClient is PoseidonCommitmentVerifier, BLSAggregatedSignatureVerifier, Ownable {
    bytes32 public immutable GENESIS_VALIDATORS_ROOT;
    uint256 public immutable GENESIS_TIME;
    uint256 public immutable SECONDS_PER_SLOT;

    bool public active;
    bytes4 public defaultForkVersion;
    uint64 public head;
    mapping(uint64 => BeaconBlockHeader) public headers;
    mapping(uint64 => bytes32) public executionStateRoots;

    BeaconBlockHeader public optimisticHeader;
    bytes32 public optimisticNextSyncCommitteeRoot;
    bytes32 public optimisticNextSyncCommitteePoseidon;
    bytes32 public optimisticExecutionStateRoot;
    uint64 public optimisticParticipation;
    uint64 public optimisticTimeout;

    mapping(uint256 => bytes32) public syncCommitteeRootByPeriod;
    mapping(bytes32 => bytes32) public sszToPoseidon;

    event HeadUpdate(uint256 indexed slot, bytes32 indexed root);
    event OptimisticHeadUpdate(uint256 indexed slot, bytes32 indexed root, uint256 indexed participation);
    event SyncCommitteeUpdate(uint256 indexed period, bytes32 indexed root);

    constructor(
        bytes32 genesisValidatorsRoot,
        uint256 genesisTime,
        uint256 secondsPerSlot,
        bytes4 forkVersion,
        uint256 startSyncCommitteePeriod,
        bytes32 startSyncCommitteeRoot,
        bytes32 startSyncCommitteePoseidon
    ) {
        GENESIS_VALIDATORS_ROOT = genesisValidatorsRoot;
        GENESIS_TIME = genesisTime;
        SECONDS_PER_SLOT = secondsPerSlot;
        defaultForkVersion = forkVersion;
        syncCommitteeRootByPeriod[startSyncCommitteePeriod] = startSyncCommitteeRoot;
        sszToPoseidon[startSyncCommitteeRoot] = startSyncCommitteePoseidon;
        active = true;
    }

    modifier isActive {
        require(active, "Light client must be active");
        _;
    }

    /*
    * @dev Returns the beacon chain state root for a given slot.
    */
    function stateRoot(uint64 slot) external view returns (bytes32) {
        return headers[slot].stateRoot;
    }

    /*
    * @dev Returns the execution state root for a given slot.
    */
    function executionStateRoot(uint64 slot) external view returns (bytes32) {
        return executionStateRoots[slot];
    }

    /*
    * @dev Updates the head given a finalized light client update. The primary conditions for this are:
    *   1) At least 2n/3+1 signatures from the current sync committee where n = 512
    *   2) A valid merkle proof for the finalized header inside the currently attested header
    */
    function step(LightClientUpdate memory update) external isActive {
        (BeaconBlockHeader memory activeHeader, bool isFinalized,) = processLightClientUpdate(update);
        require(activeHeader.slot > head, "Update slot must be greater than the current head");
        require(activeHeader.slot <= getCurrentSlot(), "Update slot is too far in the future");
        if (isFinalized) {
            setHead(activeHeader);
            setExecutionStateRoot(activeHeader.slot, update.executionStateRoot);
        }
    }

    /*
    * @dev Set the sync committee validator set root for the next sync committee period. This root is signed by the current
    * sync committee. To make the proving cost of zkBLSVerify(..) cheaper, we map the ssz merkle root of the validators to a
    * poseidon merkle root (a zk-friendly hash function). In the case there is no finalization, we will keep track of the
    * best optimistic update. It can be finalized via forceUpdate(...).
    */
    function updateSyncCommittee(LightClientUpdate memory update, bytes32 nextSyncCommitteePoseidon, Groth16Proof memory commitmentMappingProof) external isActive {
        (BeaconBlockHeader memory activeHeader, bool isFinalized, uint64 participation) = processLightClientUpdate(update);
        uint64 currentPeriod = getSyncCommitteePeriodFromSlot(activeHeader.slot);
        require(syncCommitteeRootByPeriod[currentPeriod + 1] == 0, "Next sync committee was already initialized");

        bool isValidSyncCommitteeProof = SimpleSerialize.isValidMerkleBranch(
            update.nextSyncCommitteeRoot,
            NEXT_SYNC_COMMITTEE_INDEX,
            update.nextSyncCommitteeBranch,
            update.finalizedHeader.stateRoot
        );
        require(isValidSyncCommitteeProof, "Next sync committee proof is invalid");

        zkMapSSZToPoseidon(update.nextSyncCommitteeRoot, nextSyncCommitteePoseidon, commitmentMappingProof);

        if (isFinalized) {
            setSyncCommitteeRoot(currentPeriod + 1, update.nextSyncCommitteeRoot);
        } else {
            if (activeHeader.slot >= optimisticHeader.slot) {
                require(participation > optimisticParticipation, "Not the best optimistic update");
            }
            setOptimisticHead(activeHeader, update.nextSyncCommitteeRoot, update.executionStateRoot, participation);
        }
    }

    /*
    * @dev Finalizes the optimistic update and sets the next sync committee if no finalized updates have been received
    * for a period.
    */
    function forceUpdate() external isActive {
        require(optimisticHeader.slot > head, "Optimistic head must update the head forward");
        require(getCurrentSlot() > optimisticHeader.slot + SLOTS_PER_SYNC_COMMITTEE_PERIOD, "Optimistic should only finalized if sync period ends");
        require(optimisticTimeout < block.timestamp, "Waiting for UPDATE_TIMEOUT");
        setHead(optimisticHeader);
        setSyncCommitteeRoot(getSyncCommitteePeriodFromSlot(optimisticHeader.slot) + 1, optimisticNextSyncCommitteeRoot);
    }

    /*
    * @dev Implements shared logic for processing light client updates. In particular, it checks:
    *   1) If it claims to have finalization, sets the activeHeader to be the finalized one--else it uses the attestedHeader
    *   2) Validates the merkle proof that proves inclusion of finalizedHeader in attestedHeader
    *   3) Validates the merkle proof that proves inclusion of executionStateRoot in attestedHeader
    *   4) Verifies that the light client update has update.signature.participation signatures from the current sync committee with a zkSNARK
    *   5) If it's finalized, checks for 2n/3+1 signatures. If it's not, checks for at least MIN_SYNC_COMMITTEE_PARTICIPANTS and that it is the best update
    */
    function processLightClientUpdate(LightClientUpdate memory update) internal view returns (BeaconBlockHeader memory, bool, uint64) {
        bool hasFinalityProof = update.finalityBranch.length > 0;
        bool hasExecutionStateRootProof = update.executionStateRootBranch.length > 0;
        BeaconBlockHeader memory activeHeader = hasFinalityProof ? update.finalizedHeader : update.attestedHeader;
        if (hasFinalityProof) {
            bool isValidFinalityProof = SimpleSerialize.isValidMerkleBranch(
                SimpleSerialize.sszBeaconBlockHeader(update.finalizedHeader),
                FINALIZED_ROOT_INDEX,
                update.finalityBranch,
                update.attestedHeader.stateRoot
            );
            require(isValidFinalityProof, "Finality checkpoint proof is invalid");
        }

        if (hasExecutionStateRootProof) {
            require(hasFinalityProof, "To pass in executionStateRoot, must have finalized header");
            bool isValidExecutionStateRootProof = SimpleSerialize.isValidMerkleBranch(
                update.executionStateRoot,
                EXECUTION_STATE_ROOT_INDEX,
                update.executionStateRootBranch,
                update.finalizedHeader.bodyRoot
            );
            require(isValidExecutionStateRootProof, "Execution state root proof is invalid");
        }

        uint64 currentPeriod = getSyncCommitteePeriodFromSlot(activeHeader.slot);
        bytes32 signingRoot = SimpleSerialize.computeSigningRoot(update.attestedHeader, defaultForkVersion, GENESIS_VALIDATORS_ROOT);
        require(syncCommitteeRootByPeriod[currentPeriod] != 0, "Sync committee was never updated for this period");
        require(zkBLSVerify(signingRoot, syncCommitteeRootByPeriod[currentPeriod], update.signature.participation, update.signature.proof), "Signature is invalid");

        if (hasFinalityProof) {
            require(3 * update.signature.participation > 2 * SYNC_COMMITTEE_SIZE, "Not enough members of the sync committee signed");
        } else {
            require(update.signature.participation > MIN_SYNC_COMMITTEE_PARTICIPANTS, "Not enough members of the sync committee signed");
        }

        return (activeHeader, hasFinalityProof, update.signature.participation);
    }

    /*
    * @dev Maps a simple serialize merkle root to a poseidon merkle root with a zkSNARK. The proof asserts that:
    *   SimpleSerialize(syncCommittee) == Poseidon(syncCommittee).
    */
    function zkMapSSZToPoseidon(bytes32 sszCommitment, bytes32 poseidonCommitment, Groth16Proof memory proof) internal {
        uint256[33] memory inputs; // inputs is syncCommitteeSSZ[0..32] + [syncCommitteePoseidon]
        uint256 sszCommitmentNumeric = uint256(sszCommitment);
        for (uint256 i = 0; i < 32; i++) {
            inputs[32 - 1 - i] = sszCommitmentNumeric % 2**8;
            sszCommitmentNumeric = sszCommitmentNumeric / 2**8;
        }
        inputs[32] = uint256(poseidonCommitment);
        require(verifyCommitmentMappingProof(proof.a, proof.b, proof.c, inputs), "Proof is invalid");
        sszToPoseidon[sszCommitment] = poseidonCommitment;
    }

    /*
    * @dev Does an aggregated BLS signature verification with a zkSNARK. The proof asserts that:
    *   Poseidon(validatorPublicKeys) == sszToPoseidon[syncCommitteeRoot]
    *   aggregatedPublicKey = InnerProduct(validatorPublicKeys, bitmap)
    *   BLSVerify(aggregatedPublicKey, signature) == true
    */
    function zkBLSVerify(bytes32 signingRoot, bytes32 syncCommitteeRoot, uint256 claimedParticipation, Groth16Proof memory proof) internal view returns (bool) {
        require(sszToPoseidon[syncCommitteeRoot] != 0, "Must map SSZ commitment to Poseidon commitment");
        uint256[34] memory inputs;
        inputs[0] = claimedParticipation;
        inputs[1] = uint256(sszToPoseidon[syncCommitteeRoot]);
        uint256 signingRootNumeric = uint256(signingRoot);
        for (uint256 i = 0; i < 32; i++) {
            inputs[(32 - 1 - i) + 2] = signingRootNumeric % 2 ** 8;
            signingRootNumeric = signingRootNumeric / 2**8;
        }
        return verifySignatureProof(proof.a, proof.b, proof.c, inputs);
    }

    function setHead(BeaconBlockHeader memory header) internal {
        head = header.slot;
        headers[head] = header;
        emit HeadUpdate(header.slot, SimpleSerialize.sszBeaconBlockHeader(header));
    }

    function setExecutionStateRoot(uint64 slot, bytes32 _executionStateRoot) internal {
        executionStateRoots[slot] = _executionStateRoot;
    }

    function setOptimisticHead(BeaconBlockHeader memory header, bytes32 nextSyncCommitteeRoot, bytes32 _executionStateRoot, uint64 participation) internal {
        optimisticHeader = header;
        optimisticNextSyncCommitteeRoot = nextSyncCommitteeRoot;
        optimisticExecutionStateRoot = _executionStateRoot;
        optimisticParticipation = uint64(participation);
        optimisticTimeout = uint64(block.timestamp + OPTIMISTIC_UPDATE_TIMEOUT);
        emit OptimisticHeadUpdate(header.slot, SimpleSerialize.sszBeaconBlockHeader(header), participation);
    }

    function setSyncCommitteeRoot(uint64 period, bytes32 root) internal {
        syncCommitteeRootByPeriod[period] = root;
        emit SyncCommitteeUpdate(period, root);
    }

    function getCurrentSlot() internal view returns (uint64) {
        return uint64((block.timestamp - GENESIS_TIME) / SECONDS_PER_SLOT);
    }

    function getSyncCommitteePeriodFromSlot(uint64 slot) internal pure returns (uint64) {
        return uint64(slot / SLOTS_PER_SYNC_COMMITTEE_PERIOD);
    }

    function setDefaultForkVersion(bytes4 forkVersion) public onlyOwner {
        defaultForkVersion = forkVersion;
    }

    function setActive(bool newActive) public onlyOwner {
        active = newActive;
    }
}

pragma solidity 0.8.14;

import "./libraries/Pairing.sol";

contract PoseidonCommitmentVerifier {

	struct PoseidonCommitmentVerifyingKey {
		Pairing.G1Point alfa1;
		Pairing.G2Point beta2;
		Pairing.G2Point gamma2;
		Pairing.G2Point delta2;
		Pairing.G1Point[] IC;
	}

	struct PoseidonCommitmentProof {
		Pairing.G1Point A;
		Pairing.G2Point B;
		Pairing.G1Point C;
	}

	function poseidonCommitmentVerifyingKey() internal pure returns (PoseidonCommitmentVerifyingKey memory vk) {
		vk.alfa1 = Pairing.G1Point(
			20491192805390485299153009773594534940189261866228447918068658471970481763042,
			9383485363053290200918347156157836566562967994039712273449902621266178545958
		);

		vk.beta2 = Pairing.G2Point(
			[4252822878758300859123897981450591353533073413197771768651442665752259397132,
			6375614351688725206403948262868962793625744043794305715222011528459656738731],
			[21847035105528745403288232691147584728191162732299865338377159692350059136679,
			10505242626370262277552901082094356697409835680220590971873171140371331206856]
		);
		vk.gamma2 = Pairing.G2Point(
			[11559732032986387107991004021392285783925812861821192530917403151452391805634,
			10857046999023057135944570762232829481370756359578518086990519993285655852781],
			[4082367875863433681332203403145435568316851327593401208105741076214120093531,
			8495653923123431417604973247489272438418190587263600148770280649306958101930]
		);
		vk.delta2 = Pairing.G2Point(
			[18786680396777194796086991707264341469485266483672204696181238523481704834964,
			4643824748117722983483541185379427666564303011432234388830668536908214439350],
			[12263711157414915835936369286382011310282535806363279116890586062818913031598,
			6018062989053396856532861398969952450040359375406865984740999732630529317298]
		);
		vk.IC = new Pairing.G1Point[](34);

		vk.IC[0] = Pairing.G1Point(
			21763191512158685577083517911933799197606673810451844309858440329036250324600,
			13726473062263927792360003979531240924495589049640333826477495406519668951418
		);

		vk.IC[1] = Pairing.G1Point(
			1365562294947090782239512887790873526331609535427698669936023650116102904829,
			3174633668773209142146253692078489085637203875303636500263231551278224608624
		);

		vk.IC[2] = Pairing.G1Point(
			10956182374015002204408467425327848756819631523718707154949514612564389444354,
			14436084528887728613182748250003681209821602375980408545563908878167839111638
		);

		vk.IC[3] = Pairing.G1Point(
			11329784881465718026013458454578355082127492065603307590565184979090206108462,
			1774045350300778502967267439290520186085672279369728488857982855317636197255
		);

		vk.IC[4] = Pairing.G1Point(
			307941779253314281139239164059221443144145101553286617795832073549533646709,
			20157957757455934722180643252702014590110044797384292870563888309922943890595
		);

		vk.IC[5] = Pairing.G1Point(
			7953591480885633468444910330856361123872770293996868540087670074953269967240,
			2469428366234761584071636451348900308868229578278521928005371797557332147721
		);

		vk.IC[6] = Pairing.G1Point(
			14333497813639597553549015717733291557043649878663532493718308231736132614419,
			15243696065200340524710604031429703616272121300379050086838625706252675733225
		);

		vk.IC[7] = Pairing.G1Point(
			18482556680685283628494433817161693313986511857581570923221680927341948489730,
			7831370985364761507107250319714918234044212532114686787065023834006507635799
		);

		vk.IC[8] = Pairing.G1Point(
			9543906213199847722875044848229941133500821013697600293326430757794072788277,
			18991875258865908467494940985430728026368770189648608148424128910075178207349
		);

		vk.IC[9] = Pairing.G1Point(
			20732106183296149550722690960542261370333414443869707556857709537645107047855,
			18777365490856040593357558973972205302964620262884384729566445555811953247146
		);

		vk.IC[10] = Pairing.G1Point(
			13123655164031980604767074780418720858772706036064712257112440095547982287620,
			2577636231994456429435854169837180567595839098169009523861652711050126234820
		);

		vk.IC[11] = Pairing.G1Point(
			18637673850782126876470287304924181701406363143077643257341514396090013286301,
			1724196633867057293178748393489639043795852761419456121624504640431046939
		);

		vk.IC[12] = Pairing.G1Point(
			18535381754132355115904577546613388855170633484934134256539433642140500922140,
			4543011854776992067081782402628698094658977045408431744628693031507686752124
		);

		vk.IC[13] = Pairing.G1Point(
			10414071054492188615707820122967933562908239528717887476913640400187552307318,
			9294351990676640210558234877020853527239656850065319641917573954789164959428
		);

		vk.IC[14] = Pairing.G1Point(
			10220357152417871901763225409223355475280815906057535096403887480018535465445,
			9879865699057945938514696748658224973085209814300407173497667892843318431650
		);

		vk.IC[15] = Pairing.G1Point(
			17296282020413761204823324976173033428855618369487670517195642772476416495443,
			9145029958071817248822722786829354700407682797285889353039042874103673620713
		);

		vk.IC[16] = Pairing.G1Point(
			16055100057948523121245032634677636119771584594794058766223691206027997493431,
			19020292955804937710654148020322378416708813508751081888097747591787998328511
		);

		vk.IC[17] = Pairing.G1Point(
			1257480113963838377546140749917065748374427744707632296950774064564701402846,
			14334713375115854400512787153653395322119932897971394059292553690257728913385
		);

		vk.IC[18] = Pairing.G1Point(
			11196517551156685514123330154862052393826014614350394740444181269004690489522,
			6988481000846143877546390382191664336643043967223970986325582566553083200769
		);

		vk.IC[19] = Pairing.G1Point(
			18517269909612636230301665148462716275963386142576823169313602052663771404332,
			4877182001555163669606142590662826545307663938276874531505231855324939573953
		);

		vk.IC[20] = Pairing.G1Point(
			13976297566584782879523938527825707121157906031964907598672891106155733025701,
			7868534612972399762231831308224194502030325820585214949825341161273346076839
		);

		vk.IC[21] = Pairing.G1Point(
			14726812571245342442573391870704398986638770382060421884237448282594639316978,
			14099826582336376020521928291137882839564470626375401144034982234176089266886
		);

		vk.IC[22] = Pairing.G1Point(
			10386770251864113413084663677428588304237687512991736282579458686960025563979,
			4780372479833246099550670079270491140443897997899074741589011752411330620776
		);

		vk.IC[23] = Pairing.G1Point(
			425444388829694553239243507981850444908224005516557396705029740646732368099,
			18028092471986852344690901852197191801650888742689424189246995565150929010082
		);

		vk.IC[24] = Pairing.G1Point(
			11333395626538893792053865014022375596783196894937176096081082693383632264981,
			11709062845816623578464660833996311755179651152305686834734638540463178157656
		);

		vk.IC[25] = Pairing.G1Point(
			19402095937922706199402427770808993318455372892357213079326900846642145054815,
			13619989193586727679387154529003433999806036607486791619257619706022151070477
		);

		vk.IC[26] = Pairing.G1Point(
			5393641920731732428778359881784147054956133907787578991467037748775563388449,
			13381162809975398408850066462903376789280092577218654682068783149034402380874
		);

		vk.IC[27] = Pairing.G1Point(
			1080488131958277242020435399576176540686352141829533204215613700919085251158,
			7974809292743468703184844735524462894337847973279988947923412320713345309620
		);

		vk.IC[28] = Pairing.G1Point(
			19655236705341720380805141665716677592797890852877703552184109994139834482975,
			20202909300570972915381687145081230858046049355030488382555313241490862796322
		);

		vk.IC[29] = Pairing.G1Point(
			564069205914560651165447190275021385047805875603211547572140253577754585799,
			16369258594900281200929400949679110980389334051792420296549778803292898959886
		);

		vk.IC[30] = Pairing.G1Point(
			16209922391530179086009974341959139598878840943873810309972428068517749144283,
			259267152003937207770349924867496254494510949605081340876814876383341378839
		);

		vk.IC[31] = Pairing.G1Point(
			10140371869095370961334125343345154545188820174482528146977431953645392334520,
			289495153745332185645714385097951969813474265811730594731893508738255553705
		);

		vk.IC[32] = Pairing.G1Point(
			12790662218596448128629065909678902773923326057090054364476512025191624775319,
			7385749122182794053576974556934748162908652356848230903792016756595577983536
		);

		vk.IC[33] = Pairing.G1Point(
			9063927461119286629983024252452297375811357202407995308374065521246269846470,
			9009908855692637612277610390186595611467273844840926676626092813883303807036
		);

	}

	function verifyPoseidonCommitmentMapping(uint[] memory input, PoseidonCommitmentProof memory proof) internal view returns (uint) {
		uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
		PoseidonCommitmentVerifyingKey memory vk = poseidonCommitmentVerifyingKey();
		require(input.length + 1 == vk.IC.length, "verifier-bad-input");
		// Compute the linear combination vk_x
		Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
		for (uint i = 0; i < input.length; i++) {
			require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
			vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
		}
		vk_x = Pairing.addition(vk_x, vk.IC[0]);
		if (!Pairing.pairingProd4(
			Pairing.negate(proof.A),
			proof.B,
			vk.alfa1,
			vk.beta2,
			vk_x,
			vk.gamma2,
			proof.C,
			vk.delta2
		)) return 1;
		return 0;
	}
	/// @return r  bool true if proof is valid
	function verifyCommitmentMappingProof(
		uint[2] memory a,
		uint[2][2] memory b,
		uint[2] memory c,
		uint[33] memory input
	) public view returns (bool r) {
		PoseidonCommitmentProof memory proof;
		proof.A = Pairing.G1Point(a[0], a[1]);
		proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
		proof.C = Pairing.G1Point(c[0], c[1]);
		uint[] memory inputValues = new uint[](input.length);
		for (uint i = 0; i < input.length; i++) {
			inputValues[i] = input[i];
		}
		if (verifyPoseidonCommitmentMapping(inputValues, proof) == 0) {
			return true;
		} else {
			return false;
		}
	}
}

pragma solidity 0.8.14;

struct BLSAggregatedSignature {
    uint64 participation;
    Groth16Proof proof;
}

struct Groth16Proof {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
}

struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}

struct LightClientUpdate {
    BeaconBlockHeader attestedHeader;
    BeaconBlockHeader finalizedHeader;
    bytes32[] finalityBranch;
    bytes32 nextSyncCommitteeRoot;
    bytes32[] nextSyncCommitteeBranch;
    bytes32 executionStateRoot;
    bytes32[] executionStateRootBranch;
    BLSAggregatedSignature signature;
}

pragma solidity 0.8.14;

library Pairing {
	struct G1Point {
		uint256 X;
		uint256 Y;
	}
	// Encoding of field elements is: X[0] * z + X[1]
	struct G2Point {
		uint256[2] X;
		uint256[2] Y;
	}

	/// @return the generator of G1
	function P1() internal pure returns (G1Point memory) {
		return G1Point(1, 2);
	}

	/// @return the generator of G2
	function P2() internal pure returns (G2Point memory) {
		// Original code point
		return
			G2Point(
				[
					11559732032986387107991004021392285783925812861821192530917403151452391805634,
					10857046999023057135944570762232829481370756359578518086990519993285655852781
				],
				[
					4082367875863433681332203403145435568316851327593401208105741076214120093531,
					8495653923123431417604973247489272438418190587263600148770280649306958101930
				]
			);
	}

	/// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
	function negate(G1Point memory p) internal pure returns (G1Point memory r) {
		// The prime q in the base field F_q for G1
		uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
		if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
		return G1Point(p.X, q - (p.Y % q));
	}

	/// @return r the sum of two points of G1
	function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
		uint256[4] memory input;
		input[0] = p1.X;
		input[1] = p1.Y;
		input[2] = p2.X;
		input[3] = p2.Y;
		bool success;
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
			// Use "invalid" to make gas estimation work
			switch success
			case 0 {
				invalid()
			}
		}
		require(success, "pairing-add-failed");
	}

	/// @return r the product of a point on G1 and a scalar, i.e.
	/// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
	function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
		uint256[3] memory input;
		input[0] = p.X;
		input[1] = p.Y;
		input[2] = s;
		bool success;
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
			// Use "invalid" to make gas estimation work
			switch success
			case 0 {
				invalid()
			}
		}
		require(success, "pairing-mul-failed");
	}

	/// @return the result of computing the pairing check
	/// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
	/// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
	/// return true.
	function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
		require(p1.length == p2.length, "pairing-lengths-failed");
		uint256 elements = p1.length;
		uint256 inputSize = elements * 6;
		uint256[] memory input = new uint256[](inputSize);
		for (uint256 i = 0; i < elements; i++) {
			input[i * 6 + 0] = p1[i].X;
			input[i * 6 + 1] = p1[i].Y;
			input[i * 6 + 2] = p2[i].X[0];
			input[i * 6 + 3] = p2[i].X[1];
			input[i * 6 + 4] = p2[i].Y[0];
			input[i * 6 + 5] = p2[i].Y[1];
		}
		uint256[1] memory out;
		bool success;
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
			// Use "invalid" to make gas estimation work
			switch success
			case 0 {
				invalid()
			}
		}
		require(success, "pairing-opcode-failed");
		return out[0] != 0;
	}

	/// Convenience method for a pairing check for two pairs.
	function pairingProd2(
		G1Point memory a1,
		G2Point memory a2,
		G1Point memory b1,
		G2Point memory b2
	) internal view returns (bool) {
		G1Point[] memory p1 = new G1Point[](2);
		G2Point[] memory p2 = new G2Point[](2);
		p1[0] = a1;
		p1[1] = b1;
		p2[0] = a2;
		p2[1] = b2;
		return pairing(p1, p2);
	}

	/// Convenience method for a pairing check for three pairs.
	function pairingProd3(
		G1Point memory a1,
		G2Point memory a2,
		G1Point memory b1,
		G2Point memory b2,
		G1Point memory c1,
		G2Point memory c2
	) internal view returns (bool) {
		G1Point[] memory p1 = new G1Point[](3);
		G2Point[] memory p2 = new G2Point[](3);
		p1[0] = a1;
		p1[1] = b1;
		p1[2] = c1;
		p2[0] = a2;
		p2[1] = b2;
		p2[2] = c2;
		return pairing(p1, p2);
	}

	/// Convenience method for a pairing check for four pairs.
	function pairingProd4(
		G1Point memory a1,
		G2Point memory a2,
		G1Point memory b1,
		G2Point memory b2,
		G1Point memory c1,
		G2Point memory c2,
		G1Point memory d1,
		G2Point memory d2
	) internal view returns (bool) {
		G1Point[] memory p1 = new G1Point[](4);
		G2Point[] memory p2 = new G2Point[](4);
		p1[0] = a1;
		p1[1] = b1;
		p1[2] = c1;
		p1[3] = d1;
		p2[0] = a2;
		p2[1] = b2;
		p2[2] = c2;
		p2[3] = d2;
		return pairing(p1, p2);
	}
}

pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

import "../Structs.sol";

library SimpleSerialize {
    function toLittleEndian(uint256 x) internal pure returns (bytes32) {
        bytes32 res;
        for (uint256 i = 0; i < 32; i++) {
            res = (res << 8) | bytes32(x & 0xff);
            x >>= 8;
        }
        return res;
    }

	function restoreMerkleRoot(
		bytes32 leaf,
		uint256 index,
		bytes32[] memory branch
	) internal pure returns (bytes32) {
		bytes32 value = leaf;
		for (uint256 i = 0; i < branch.length; i++) {
			if ((index / (2**i)) % 2 == 1) {
				value = sha256(bytes.concat(branch[i], value));
			} else {
				value = sha256(bytes.concat(value, branch[i]));
			}
		}
		return value;
	}

    function isValidMerkleBranch(
        bytes32 leaf,
        uint256 index,
        bytes32[] memory branch,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, index, branch);
        return root == restoredMerkleRoot;
    }

	function sszBeaconBlockHeader(BeaconBlockHeader memory header) internal pure returns (bytes32) {
        bytes32 left = sha256(bytes.concat(
            sha256(bytes.concat(toLittleEndian(header.slot), toLittleEndian(header.proposerIndex))),
            sha256(bytes.concat(header.parentRoot, header.stateRoot))
        ));
        bytes32 right = sha256(bytes.concat(
            sha256(bytes.concat(header.bodyRoot, bytes32(0))),
            sha256(bytes.concat(bytes32(0), bytes32(0)))
        ));

        return sha256(bytes.concat(left, right));
	}

    function computeDomain(bytes4 forkVersion, bytes32 genesisValidatorsRoot) internal pure returns (bytes32) {
        return bytes32(uint256(0x07 << 248)) | (sha256(abi.encode(forkVersion, genesisValidatorsRoot)) >> 32);
    }

    function computeSigningRoot(BeaconBlockHeader memory header, bytes4 forkVersion, bytes32 genesisValidatorsRoot)
	internal pure returns (bytes32) {
        return sha256(bytes.concat(sszBeaconBlockHeader(header), computeDomain(forkVersion, genesisValidatorsRoot)));
    }
}