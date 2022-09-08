// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "./utils/Ownable.sol";

/**
 * @title The BigMacRaffle contract
 * @notice A contract to determine winners of BigMac lunch with Sergey Nazarov at SmartCon 2022 powered by Chainlink VRF
 */
contract BigMacRaffle is VRFConsumerBaseV2, Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    VRFCoordinatorV2Interface internal immutable i_vrfCoordinator;
    uint64 internal immutable i_subscriptionId;
    bytes32 internal immutable i_keyHash;
    uint32 internal immutable i_callbackGasLimit;
    uint16 internal immutable i_requestConfirmations;

    uint32 internal s_numWords;
    bool internal s_isRaffleStarted;
    EnumerableSet.Bytes32Set internal s_participants;
    EnumerableSet.Bytes32Set internal s_winners;

    event RaffleStarted(uint256 requestId);
    event RaffleWinner(bytes32 hashedTicketConfirmationNumber);
    event RaffleEnded(uint256 requestId);

    error RaffleCanBeRunOnlyOnce();

    modifier onlyOnce() {
        if (s_isRaffleStarted) revert RaffleCanBeRunOnlyOnce();
        _;
    }

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords,
        address newOwner,
        address pendingOwner
    ) VRFConsumerBaseV2(vrfCoordinator) Ownable(newOwner, pendingOwner) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;
        s_numWords = numWords;

        _addParticipants();
    }

    /**
     * @notice Runs BigMac raffle.
     *         Reverts if already called.
     *         Reverts if caller is not an owner.
     *
     * @dev Only owner can call.
     *
     * No return, reverts on error.
     */
    function runRaffle() external onlyOwner onlyOnce {
        s_isRaffleStarted = true;
        requestRandomWords();
    }

    /**
     * @notice Draws additional winners if someone is unable to attend the event.
     *
     * @dev Only owner can call.
     *
     * No return, reverts on error.
     */
    function drawAdditionalWinners(uint32 numberOfAdditionalWinners)
        external
        onlyOwner
    {
        s_numWords = numberOfAdditionalWinners;
        requestRandomWords();
    }

    /**
     * @notice Returns BigMac raffle winners' keccak256 hashes of SmartCon 2022 ticket numbers.
     *
     * @return BigMac raffle winners
     */
    function getWinners() external view returns (bytes32[] memory) {
        return s_winners.values();
    }

    /**
     * @notice Requests random values from Chainlink VRF
     *
     * No return, reverts on error
     */
    function requestRandomWords() internal {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            s_numWords
        );

        emit RaffleStarted(requestId);
    }

    // @inheritdoc
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        uint256 length = s_numWords;
        for (uint i = 0; i < length; ) {
            bytes32 raffleWinner = s_participants.at(
                randomWords[i] % s_participants.length()
            );

            s_winners.add(raffleWinner);
            s_participants.remove(raffleWinner);

            emit RaffleWinner(raffleWinner);

            unchecked {
                ++i;
            }
        }
        emit RaffleEnded(requestId);
    }

    /**
     * @notice Adds keccak256 hashes of ticket confirmation numbers of each eligible SmartCon 2022 attendee.
     *
     * @dev Callable inside the constructor; Turn on solidity optimizer with 200 runs.
     *
     * No return, reverts on error.
     */
    function _addParticipants() private {
        s_participants.add(0x641b11da408590705534ed5490f73a3b2a67b5a863e46bc5d91322f67eea15ef);
        s_participants.add(0x641b11da408590705534ed5490f73a3b2a67b5a863e46bc5d91322f67eea15ef);
        s_participants.add(0xa19feb02fec238cf38a8b3c705f86a9e5459257a9a41e25dd8ebbcb0c6aaab6e);
        s_participants.add(0xc6e41e80b39c3c58626f32d6f57aa26ed2dfa90639c6fdd81b4304b38627a0b5);
        s_participants.add(0x756640c74d245e4d0003bd2fe35e03114ca1d01f4d2bc3fae69e5ff46bbaa848);
        s_participants.add(0xcead56737fd58f6ef896ccacb5523b90accb921738df2d1ebe69b08615be63f6);
        s_participants.add(0x2e843a5100663bd2484904fc6d0a27dc593d09c95013eeec75ba723a53c3880b);
        s_participants.add(0x9ed9831bccc8a109a23e67ca778fdca3985a95d19ef39904f93be5b98abba8f2);
        s_participants.add(0xff6be7db6902b7956c6da8ec6ba021d53102f2c512ca8145a3bd4b8aab8596c2);
        s_participants.add(0xd85daa67a18e148827a490bd89d40614ca739d41edd7507597f25220cbb958f2);
        s_participants.add(0x30964ed4d2f4964b8882c440de7addec87b777d8b73a7a3f9cebf6dacc358b7f);
        s_participants.add(0xb197798873afd284bdfe64b4ebe7c3445bed4a12f7a806bedf4a17893b1bcc8f);
        s_participants.add(0x8a01c93eacfdd1d91599f5f73a9812cf53f2f4292d41355362d7c101a0856594);
        s_participants.add(0x6899b6e3c8747bf6cbb953cd0c82f8778de170dc609b05a04d888d27455ccfe5);
        s_participants.add(0xa8ba68cc4d096754a816e1ca4408df6d77c18c58e3bfa2fde3af5f463630bb9e);
        s_participants.add(0x7f6ad5c4cbe8307bcaead6ab05661ffd95ccee397e9aaa0f720bf1d94a52cdda);
        s_participants.add(0x2a5063c2f863d2d63a390a6e794d7255dfb1310209a62eb3283f3cbc8983ec37);
        s_participants.add(0x762c42da99e84841e023ce8fb770060c3ddda5455eabc8ea5b0d4dcd827f62af);
        s_participants.add(0xe62fc8cf112b6335ebc7fcb25b551c12b0ae1a7ee57d046f29c885ae9894e48b);
        s_participants.add(0x0f007ae7531709f489a90c3900a881a99fbad6ff1e7f91bc84aa165fefd1b40c);
        s_participants.add(0x929053d010f74133d9dc34e4be193e7d60b512382be5b04569a5e8ca12e7dc52);
        s_participants.add(0x42f5ef20940cafab8387e78ecb4a8e69d138c95403ad15aaa302436c9e55ad55);
        s_participants.add(0x5869dce3c57a06fcfd10c61f6d290cf7e6aba8c451ac6e3ff7a3bfaffa00f98b);
        s_participants.add(0xe1f4e18eb301c14e7d06659098554757f790fbacbaf7e68dc4bfe6c4450afb86);
        s_participants.add(0x0fc1422616b0ef5bea7471de18f8367743013a8414aece259b2ce5b344bb343b);
        s_participants.add(0x7cc658260452f0e0a24ad15406ae5f8e245e366d7d1618c449e3e6086414cf18);
        s_participants.add(0x264d3dcbcb11ad7508f37a8d7bc26403ed947e57f1f88ada95d0a0efb0579943);
        s_participants.add(0xbd69c9ae3ba74511a4068163b5b4b2c6772862119a80d09961269b47f8b3f930);
        s_participants.add(0x5de599c142bc880072143520b31eb8ce3937ee07407abf748fb785ef5fb411bb);
        s_participants.add(0xc4ca233746475eec5680a752f85e62be39580f93b42c746e5a5a09b97b9167a0);
        s_participants.add(0x4f1373ba5102ca9980c1c7aa7f9c6ec6150ce039fd76466e898b236711750fec);
        s_participants.add(0x508b8e5e978dc957f3279fc689c0591a9896cecb27f6fd376430af23495f27cb);
        s_participants.add(0x3f71c787d1a8c73c1a5edfa72d74371f431838e43caaa86462b1ba7d5c6b3004);
        s_participants.add(0x348d46b20abba97f1c1d3379171ca92ec1e3ec65458ef01f8c6cbfb201ff7e35);
        s_participants.add(0x818e16b1918ebe84fc8bbfebaae5e741d4f893fa699567a672425e2a008c8ecd);
        s_participants.add(0x4de996ca2823268aa9a455032ac62abeafa5a6185383eb1d9ff9774e5d6ac079);
        s_participants.add(0x1e512f1734b34a15b6783bbe4e28ff95360a888f4c4cf873a19287af04b783e8);
        s_participants.add(0xaf4416a7b3501ecde930fdb685bf66c9f4bb77c2a580d1132a2160b3e36d1ad5);
        s_participants.add(0x5e84b7a5353d4957f1cb948b4823537ad930b10bc532a9c30770a45bc715c111);
        s_participants.add(0xc30fd25e891589ddc9465bbe408ebc7eec9436d60e51563f732b01f1b0a92078);
        s_participants.add(0x37b5dd4bafcbb4ed9d853e14338249555aad8b10ca4a81089d17cc187a2d2acd);
        s_participants.add(0xb05df877207f692663d2bbb7584d531167fd36a97ff5d6f8f5e0c3ba386f8b73);
        s_participants.add(0x6850386a74016325460156ac4b64aa525761d1a346b848ce4023c0cd77a457bd);
        s_participants.add(0xa258176d94f22c437613f49048e0a1698a828ac0f9e6f4a99789897303f5489d);
        s_participants.add(0x9af0280b32aa19474f4ade1f026d50664cebe2e383d3c48ae427c99bebbd12ad);
        s_participants.add(0x5cde34f633a21b86c8ae5313a9263d704038fbe667f823e84b1f0fbbcf6bcb4a);
        s_participants.add(0xddbf39571cdbc981733cd0b7f1a52fa2604048210fcf8bdca7584aded940e4f8);
        s_participants.add(0xaf136061e31321f0b0cf825508f8808c8ab12701e8bcc967e925f14b9dce1f89);
        s_participants.add(0x8762279fd938c688142b55c6a21a8d8c60945648e6d344de1457ab17b868a049);
        s_participants.add(0x7e1005b08acf46f07f4ba46602c7dc3333c4be1dc3b07a7b61108c0fcf1faa3a);
        s_participants.add(0xf689fc5d26826a6de0bedc5268aabc98b5307caabcf571cef61bbe1a7cbeea81);
        s_participants.add(0xef007bdf6427564f997c2f71068bf503d1d6172bbf48286e4762a7b30d60c8d5);
        s_participants.add(0x5d99a801ba3b5831b857154302017195a1940f85dc670b3eeaf5ae5f6784e06e);
        s_participants.add(0x1c5f2bdd0e19700e308904603b69cd300e40cfd8d18c7e5b04862dbf7b52023e);
        s_participants.add(0x26f3e0e6193f02c3137d2d23338c19a2f16011baea907a6debf46e2b479340dd);
        s_participants.add(0xbe3b5c5224f5d79f6975b6c085d6a69aa1f53cb261ce64e13ce50ad1daca9667);
        s_participants.add(0x10094660fb63d7b307617b177e21f82b05c28e0d6a48dba7450eba9bc98f09a2);
        s_participants.add(0x14064b289f4c3d6004d62e698b28083e5151b3ddc59e5b9e1f593b7e3a1806a0);
        s_participants.add(0x9826a073710461a46a72f6623245072f0121f0206419dda4357cabc7f69915bc);
        s_participants.add(0x51ce3e5fc1533a121d42d379948005f232c8d2a263c175dbac3402e96faa72e5);
        s_participants.add(0x246cd2491f5ab0f5aa56caba814981acd79724ed8e31fabfa574dcfd94e04fb9);
        s_participants.add(0xf12574f6c270840dfa5ccb7345f44dc05750c960f629e4c908ec9994ed8b8fba);
        s_participants.add(0x6643ed22722d3446797a0f38773c8e64640ce8a67189696b7a428f7619335dd7);
        s_participants.add(0x4056b59a44ff450e42a9b4acc0e37870b64b7333c43d36df3fa4491921815f91);
        s_participants.add(0xf34c1e8f1674f586cb6aa6dd654c1459ab25b81d3f2db26162b839f2517b7db5);
        s_participants.add(0xc1fc8c454069aedeedcc546564c04d8117b3f95573322a094fa5ccc57088d7bc);
        s_participants.add(0x5417a85a546d69f142deec8e191644f05212024253d4b4d400b122badca8d888);
        s_participants.add(0x153cb56403174e3e8681b5e2f9db5c15a8a9c38ade78efbfb40b5d95d929170d);
        s_participants.add(0xdcb99ce89dec868a610debb50f1cd68555ac75197c43891be58857835f05e014);
        s_participants.add(0x1049d5e520aa67069acd08bd4c62aa459afc08d215bb40cc19e78d474acfeae3);
        s_participants.add(0x8988f55288729a137e5003981a56db0c5eb2a400be05c87501ea16107642b175);
        s_participants.add(0x8f6fe09611cfd593a235f6c890144b8095f523805751f52d72df5725590da6fb);
        s_participants.add(0xf818da10c53ddca3358671567b03cc9622bec9f975bccb6e65be1476d5a3a3ad);
        s_participants.add(0xb8bde07b182974192530e48d284c13c4dfaac44010f0761bdd23113ccb82716a);
        s_participants.add(0x821406afe228718d2ea5ddb18407633df33d61cab659ad52fb1831ae0bd7ed20);
        s_participants.add(0x52a7b73efebb6783de8ef96bfe0221f694bc63ff7d2c7808ba4ab93de0fdf03d);
        s_participants.add(0x62530d565bf64ab0db0e956394fcf65dcf972a379f4999f4a416701417ecbc4e);
        s_participants.add(0x95e26c82417016dc30c61e3d3babf4bac03503cb7555e6f4688cebaf81cdb5fe);
        s_participants.add(0x3407e07c3567a36055b90beef282db7781651b561a537023d4db9a4175dbe5e5);
        s_participants.add(0x1c2188c67f12fbc9380c15dfe8c385ce1914f8bb41fad2ed58a878298f631de2);
        s_participants.add(0xc00208a5b055ba062454be9c8234d9d0ce9a9fa3eb25b500543f62852d9d70a0);
        s_participants.add(0xe732500575702532c131faceef978523280a74cddf4f562beda21acb11101809);
        s_participants.add(0x9a5a9f9d334e0683c2b0db4f187c0e305e2cfcfefc7ed98dff32af045139be1f);
        s_participants.add(0x4bfccaa52f3b45ce72b2240c2545167c8a9cb98c8d88144445d823a2fb6a8b33);
        s_participants.add(0x5e054bf362f50357082ad8cb91c0fcb126d281047defda0db23b4f544a3d8eea);
        s_participants.add(0xdbc3c2b2612e13b5b00d27b237155fb8923be9b43a3ba286abbbd6c81dc83252);
        s_participants.add(0x80328085c8eca24b9700c941e677cc95c81345bfb45e88e5db5600c3e414dd2c);
        s_participants.add(0x7b050e0dbf480487cf522a0bab2e6dc73dd9ab4a2793871f254ea08aecf14eae);
        s_participants.add(0xb9cf17524c196635f410e7428f162a5c930071a9d931db39ca923029913a27d4);
        s_participants.add(0x0fbc695d5a7452d7b981870a10ad2f21c204dab3d0108ab5f5c894207b2f2dee);
        s_participants.add(0x8326368945d8bb6f6839d1421b5426f6c029e2a0e8ec1fcf9d8c8993f3fe3cb4);
        s_participants.add(0x3930fd0fcba7213d093509815e0157e2ed63a6233ea74ec509183bd06fc3660f);
        s_participants.add(0x54480d87a3b7a04ea754d3c1bf006d38cb8dbee83d596c55afed6fd424b1195b);
        s_participants.add(0xaf8dc73766dea29a97468d46f34a59591e9af8baa335d09671c68a98c63bb504);
        s_participants.add(0x71c9da993d836059f55468691101ede93dc7b22480d2be2db7ee6ca8d6352dbc);
        s_participants.add(0xa14e7f9f8944f4cb10c07903998e38b58637db898ff732b3e3f40e002d3c03bf);
        s_participants.add(0x5cb3f28f47f4ed8ed479c3f38f20fa25c3b9badcdc7b9d769095cdcecfbdc02e);
        s_participants.add(0xa0f72f05f14cc08abeaf1f326714c423504a37e1d9dabc6d20b2d11ec0a8ab33);
        s_participants.add(0xb0c3d5c672d2718c90150034ee01d8e94b1c29dc4865521f96070d9f783e0efe);
        s_participants.add(0x3d9965b015864508868183a7c55512a5888fbea133502bb22bc29f9cdef4fd75);
        s_participants.add(0x68b34b79cc7cedebe06af59e4b0fad174ab249a0f280183a6184886e30c4eff2);
        s_participants.add(0x0992055a67319c847324b16734b793f43730a0b5ba489b013ef62c2eb4ba0cb9);
        s_participants.add(0xef551168b60c4021724da63e2b640b0b8375425a283292c5e09c0ae20122839a);
        s_participants.add(0x64a806ced4c421a8742c35c071a3b5a2bad4164b9b635b35530be814fa407b8e);
        s_participants.add(0x931e0dbca7f0a975e3a0e8c560bfa0dc789dd1d17128fecf462792284d35bc45);
        s_participants.add(0xc714f79decd51a1bea8e28cf398fb4c453748710fd142c19fa9aca6e1f4717b3);
        s_participants.add(0xe29be228296cf409240e8f55406ef77d5f234fbe0cb3f81e98c0bde962a79a49);
        s_participants.add(0x8021fae1f286c93b1a02580deb7f758600e0f4030278f306aaed43aa82d0a337);
        s_participants.add(0x9da736bf5210bb1e6fd9571c082fa49c17cf021003e59fea03d9d1db5210635c);
        s_participants.add(0x47f1e723af2caea5a0ac96e967fd1bf7f4994146e87ca4041856f3a15faa5d22);
        s_participants.add(0xc05c42efe7d4522815ca8fac708ed30034cdfd2382e03df6ad01ffb97ede59df);
        s_participants.add(0x6cf430d67bed48b6debca3ef47e9238d7b18fb39c1752b946c5e8f4eced7ebb5);
        s_participants.add(0xac2edc754d25d9944d47a6c654080430555989211b4087330a8603d4b17027cc);
        s_participants.add(0x4a075c9bb984f46c6d44a302487d68853029180f7f70376553c4c0f0d4a023c3);
        s_participants.add(0x635379b15998c4e0adfb9ee55612bea24423c267cd0c0808987b2a9c00eaef6c);
        s_participants.add(0xf8d3db573063f47e58e46a7468599d4f86c29aea897f84b30276e33b75ab9fbf);
        s_participants.add(0xf53dcd2cfa881a33e93bf34cb2790f4157573d1a6fbc49dc69240ee857bf7e4d);
        s_participants.add(0x9b775cfc5cfd4830f9d647aeed7477898b63e28c2d7c2a61d5f120a987ecf2da);
        s_participants.add(0x3a393971ea55d373d999eb6ed2314c525c784eae200e2e192a1e9ca0a0f11809);
        s_participants.add(0xd263a056050da9de6f697ef9f258fd83d05fb846c384c5555dfdf38f26be3dde);
        s_participants.add(0x9166ef5ce65967db7f6dc78b4505b97306df6a2ba6a83f93e79300421a759d08);
        s_participants.add(0x3607dd718ad455d824765d0b0c946fb0dd22d24d3e043a4faf4f1cd22856e502);
        s_participants.add(0xb10e3cbbd3c9e40e38edbeeccef10ccff47f69d04c12f614ef09ab357382ab46);
        s_participants.add(0x7bc0eacd977b5987904e1374371f8f7e8ce9be0f7adae5bfd2a7d8fd7707239f);
        s_participants.add(0x468c2193fe46652461b3109c64c4a0b654113a50f9bc5553044f9928643189ad);
        s_participants.add(0xc07ea6c5321f47c39f9011d13386bc3aab1cdeb4eb7a359eca65a7dc34d853b9);
        s_participants.add(0xe3577379148a79f97d07ed952f952f239e65511b76300d76cfae3196787d35c1);
        s_participants.add(0x5c52f0d8dc1aadb49e73730ecc0fc91eb996b1f614c7e445016b48915c8526ee);
        s_participants.add(0xdbb1bd40dcca11a630b6e64a55e1a64da15e23c151b082907393a5a897636848);
        s_participants.add(0x80c7f28abbf3a045e90f3a830d206da8f3c62aa1620bf6e26970548efdea82cb);
        s_participants.add(0x6c19755ec4f3d3fe22f8a5df245c2e8d5a92ecd6e33acbfb0732e0e41bcc4308);
        s_participants.add(0xc54fc9512b9f619dcb52e8f43991802a5af1ede040c733c709b89970e48011d1);
        s_participants.add(0xe8136d45d3d795fa36bbb185516a7f6594c7d35eb1c8c5d88a4081d59583ce93);
        s_participants.add(0x3091918aedd3736eb2a8bf13c8ed1e0591121f0e9bded896ec6a768b0c3e5843);
        s_participants.add(0xfd276c6d90a7b583fb8add0d70da4ab23000301b5fa30c9de9720c6812a3c34c);
        s_participants.add(0xfb2f0aa4e3f95b2d9d480361be10df51fad68854348f27a698b2623d64badbe9);
        s_participants.add(0x550cd7e61c64643351373b0b22cf3e78503f7ded5dd56fa052735a900ca8384e);
        s_participants.add(0xab0e2df5162e43f4aa077e98aab9e0f93283ebd0c8a372c061f39d63632ca2a9);
        s_participants.add(0x57108939f7d984bbb5cf6612b555d2d21ac99840649a4ebe63fec5cc158db04d);
        s_participants.add(0xfe0ddbffde233e548f1cfb83f39a01afd4c8a2bbfd069371e8053c0ac7506745);
        s_participants.add(0x70f135894bf684fbebe2b37162b73f8901e7ad021bd3fb7b92ca876c0fa9ce5f);
        s_participants.add(0xc2296d861dba29a8cbc07c736692f2cd6c4a24ee7a9b4528a338271769c86c79);
        s_participants.add(0x79ae52babd7be42f6c702711b5ac29bb3dec0d338875a75c7a411a17721d5828);
        s_participants.add(0x04f857e1154fa59afa4a73b804aa908338d4c6b1d513162cac85aea2561821e5);
        s_participants.add(0x5ec206500111c8c41f56d1490b1b4558558a96a030dbf38ccb5beeed647a3964);
        s_participants.add(0xd34044d78d968b4dbbacd79a1768ac5fdc8ffd6aefd315daa350c6d20d5cdb29);
        s_participants.add(0x4415b4b28029acddf0c3e6393c4c264a86f07c39d5ef117fc15ffdd184b3c5a5);
        s_participants.add(0x7d4c6b8ead1f3bc33195125240b158511dff0612077433350f561f800f7dff5d);
        s_participants.add(0xfc448a46b12ca6bf9c540ee493ea5b78d409fc25528f13b4765e48665db7b78c);
        s_participants.add(0xb263afba6626665ef22ad6c09e4f0b3614f4eb4f7e84b3155e758b6266811c91);
        s_participants.add(0xd2b328089b0d548fdb14bb0ff24da6f566a4fcd468c4ecce43c14766fc866bba);
        s_participants.add(0x1b0622b0ff3387c5ba0215fd7bf36a50f3c1e60a5ec9388da699414ae5c97873);
        s_participants.add(0xfea6daceea7f576af1fbec86d02da0f918e0d84ba6e93ada4be52179b8cf90c3);
        s_participants.add(0xd7180c9f1b22d8f3d06124d64220b2cc0be1b7368c3486a9c80ba6062204d2ea);
        s_participants.add(0xadb4f8db643e10586617696fc037ef016435d0cb4593f3e7e062a89c8eeafac7);
        s_participants.add(0xc0fdbb8af3243b57d4f0a7d292b61d310d590eff88ebdf39ea2215732414bb89);
        s_participants.add(0x104f211332ea14679eba4f9028e6aead35cc1fde550fc342ab1dda32d46d0a8e);
        s_participants.add(0x70666371c8d81c68efd591abad1e8949cdeb72375e72b77a6c9078e2ba4be3ca);
        s_participants.add(0xa1b97a8ae2b97ed885ec7ad55798aab0bb77c93458ad26e3100525620fe586ca);
        s_participants.add(0x63987333dd65d2e3514c8e1c34bb3018877e611afa935da69685ec8279afefa7);
        s_participants.add(0xafaa4cbe5bccd202c2f96b90e8b765635a34480c0ee014e3e2111fbe11b2e974);
        s_participants.add(0x2c5d607ed4db35d982028af31be35c530fad05246b03fb62a4ddfb6436b9835c);
        s_participants.add(0xef4016a56baca82043e030f66fb96e8a3cfb94a371dab5c17c58209abf2333fd);
        s_participants.add(0x433df8cbb680885f5cb234f6d549396123a5d50b048e9b86f7c01cd14d120a18);
        s_participants.add(0xb1c1771fce7fd730607ddaa405683aa8f0ed64101b98f1ef022193ca4d14eddb);
        s_participants.add(0xc1eea1ade90dc5c73cdc05ab99c5fa63192417059d0220fce54b3608bb6a7e6c);
        s_participants.add(0x5397abe91dab12b2c4638237a8f7e48f40d215083eaa6c6d411a198cf6d094f6);
        s_participants.add(0xa1d382488f9cd19e25d82461136bed9b14f8699af0ea60d2368cf00d2027d0c7);
        s_participants.add(0x3bf0d5cfff8e8205755e5a39b63850fbf7d4a6cbaf253d0ce296f804365d5ea4);
        s_participants.add(0x4d08139d555a7f4a254f5384a890ce767ea50d00cd757dcce5a58729cf9c6dcf);
        s_participants.add(0x5fc388dd66e4a8ec6143a0bf1900c02087ed5cefde62ca20ebe07728877e83df);
        s_participants.add(0x2ebd2024176b5419b5dd06264a5080b7e778e8a66c2419de33e8ae056a5915a7);
        s_participants.add(0xba6f392228c273ac20719b544750a8860538b3d030f1afd0c1f5d43a5c9b420d);
        s_participants.add(0x4f87590204eae209feb2d15ddcbabe71d29e855b621cf26f91600dba30e1983f);
        s_participants.add(0x755f756684b269ebd9f0a31507f840a59ea1b0228530b7630974d233090f4d44);
        s_participants.add(0x8a1d3f5c116db6e22ce61a045cfa51b76f8ec6686515a4bc5e327b39fdae3733);
        s_participants.add(0xa810c68a8a01445963af6f3e07ba2e8d7fe073b4344b1a4051c58e0bc61bc623);
        s_participants.add(0xa213054a7d300372cafd7d3739e276ccde6348a9e388d755aecc86fa687ef858);
        s_participants.add(0xf39815f890f1545cb81036456b16949f4a082749ce51868fdfe2ea0db296d630);
        s_participants.add(0x2a774a6a18bf852efb274420d22726e1d6434347447348c403ac5f0c89edb1ec);
        s_participants.add(0xf3be8e1ed3eba0b0d72d8ddcab36afd7863dd8d2427dbde37efec1616192e2c4);
        s_participants.add(0x954a34624d8e216a78147c2a39638e8d3343de123e92825bf8ca29583bd4ff27);
        s_participants.add(0x86ff91de2898185b8b084180ca06cdf1e84445d49771edfaeacb89ef7dd91d37);
        s_participants.add(0x6c3e08f9aa08a89a51c94c78c46f7ed132b4c0762b9d8ea93a85f736ab709524);
        s_participants.add(0xd7f97644305b9c8a2d96b743b73cbc62565aa9b5c0b66bbfc2d02d7cfc717169);
        s_participants.add(0x35655d7ea4e2e43c4a716f9947579cb0d2926660d92e821a707284d42c9cfa02);
        s_participants.add(0x8fcc43a5aad6a330d3817c8c7f7d56d9c1d304c39a2c3efa917f3fdfeafd13db);
        s_participants.add(0x839f9736937fa39b656475e0a60f48c821ecfcc6edda659e6b0ba6e8bc2106b4);
        s_participants.add(0x4dd5caebfe71ad0d24777b7ca74f6d575ed68834521387b2d64cd1c5a3f8f07a);
        s_participants.add(0x6190a0f51058f4b3db43257086facf120030e7c495544e2e22bab7f28f0a89bd);
        s_participants.add(0x462addfec82d4f2cb6a87cca636a7f93293289ec8977987ea079f2691868b0d7);
        s_participants.add(0xfe29e8e1b7e3ff29132ec3e947fd34d5433a3ee122c59dc9925b8814d15faac8);
        s_participants.add(0x4411ea8e1e59d552da7a3af8d0b1c3828186936e885a68e393923b4ed8654417);
        s_participants.add(0x1593d94bc9326cd1bf0be652c5500ef1196c974b2deac213c46ad882b060fce0);
        s_participants.add(0xe226493c35ef15b956fa5a05ea77e1b626947dae67ac36da954213c4b533f33d);
        s_participants.add(0x5713a12452f2555523663e349a69d25e591f86802aa0c18425bcd7af5baf0dd8);
        s_participants.add(0x4df6ef3986c890740ca2d1bbd67e063101b9b1a6c521728382881700444ccc53);
        s_participants.add(0x7377bfe914a0979a5f6dd9c5242e03892cc26e11262820bba541a28a8f9b908e);
        s_participants.add(0xd177789eedc7c94c66810400b632a79158d8a3ad8760e1149e806ea8e2b1f987);
        s_participants.add(0x69a0f05bf4f7b826738f82c11366397e60de78abaf111941538c5f45021e095b);
        s_participants.add(0xc120b4d20493030bfca3b5d1f85287dc2715e87e40ad0ecfaa87241cf4412a74);
        s_participants.add(0xb801015261a1dcba4021c68c72a3563869cee42862f9757b8e4dd15683808bbc);
        s_participants.add(0x16673edebecfb7f3860afd99af430d27228fceebf0c58acfa800a96acd509500);
        s_participants.add(0x3eaa5af44fc6dd74253f1e595a559e1fc90fab77f5a96ebf721d76d1b95be2f4);
        s_participants.add(0xe9e47c1f3b9205373c352ef927e5924c82c285f32d994b59caf702de9ed6730c);
        s_participants.add(0xb0d304d343a1c0dd043552b24fc6bd614e9a3f9c061886910724768b2596ea00);
        s_participants.add(0xf6956c3c7c2e4a77d5eca28f0d879c59c96acd9e98ead950321bda25701fc234);
        s_participants.add(0x03a3631e2274cd125c80b84c67c824988e09707f7622badb1399cb4f52837c14);
        s_participants.add(0x8ff853b8e4d0fdcfa574603958e5571c35dbdde517a8a322fb7797b25547a00e);
        s_participants.add(0x1c87e37289472fd0e399ce2c5320244c726f9636d566435ace6525dd62e01150);
        s_participants.add(0x72f130fa9a6397c80999b9057cb579754472142dc411cb6fc48cc5e9ec1ad056);
        s_participants.add(0x54e4a4c22e190b63f1fbdb231aacf417fb40a288096981a420451f39fa7b384a);
        s_participants.add(0x2aaa45affb34e5ccdfece5ca9dff4dd3014a5651f9b44123489b12dcad83d2ac);
        s_participants.add(0x29687b53a1814b9496b7a141660054c835c0324e4f0851e849e5aa6c640357ee);
        s_participants.add(0xab6c0333b6544caece6087ee699940b1cb3c6b1b696690dbdfc45c92e23fc414);
        s_participants.add(0x3c023a5081ae97fb4fa214d233e4831c61168b41be5bb6c1131e42fbb29622ec);
        s_participants.add(0x58bc086d6c0abed01c03e3d7d5489289035ad9afa7d496f4d3fdc5d0216e2279);
        s_participants.add(0x4121e62e50c9b6345f60f9647274947689c2f1450d413010531061d303082724);
        s_participants.add(0x680e9ac1b62d2ad60a81cbc5432a924345ff0a1512286411bbc6a7734578169a);
        s_participants.add(0xd4eb5e1f6ce5f4dd4e7e6a750818c26d2fa6e637a7dae81b8f1345fe2c755857);
        s_participants.add(0xe5e913b7afd7adf2916f16f5afe20356f103aa95bbd1ac677e6e4abb4db4b480);
        s_participants.add(0x34864997261a28df47cc2964ec407c1041d7e7df72cf47f38cf6a839df5d3272);
        s_participants.add(0xe41d53b4a77d09c7364b27c6871d38caaea726754b7f1097e800a44ba6123a41);
        s_participants.add(0xb6baa9831efe69c8eb50549c10185b77b03da4f54ab17e0f8127e80543ab27cc);
        s_participants.add(0x994aab0af51ac8974815b9961f7dd52d5bc9a0ea9dcdcef89b21d782ced859bb);
        s_participants.add(0x4d6d86936695818f0f9f825e44481f107817b1f572f63e89b64570bef9a7c116);
        s_participants.add(0x03fb6cff3cc9f1e962fac373b0be6a94d60e9a27761fcdf226ed87eb2fcd2637);
        s_participants.add(0xae7f00a4818ab5a5119934280c0a428467ee0ad444945515b3a5c47c50136bce);
        s_participants.add(0x0805a75f3919f40267219c2ca7ab024ab20530190f7c6af210ad65df0b14ba2d);
        s_participants.add(0xc6fb9f904f301c37042f5af743b18b2cb9d282813d711bb9d6bfaab12051b028);
        s_participants.add(0x9f9a4a95e8e5b49694aab665951089a675bbc73e37a50893c020981a31d91a73);
        s_participants.add(0xe3e4d4c03d380ad2d082bde761f2196d1e2ff856868c8fc3ab634a16e3a47d88);
        s_participants.add(0x37c851bbba2eaa91f3f0fe4364941644c5031384844e4979ec5835a6795148f9);
        s_participants.add(0x67c7d787a6d4313e3afbc0a77a5fdacbf9d8b7d79ddb78c589d2755a0262d6ef);
        s_participants.add(0x54ed3ebd9708f57ebaf0ffdcffe56aed6efa4d52d74aec9a3d220e54d8191873);
        s_participants.add(0xbe5c41ab1a88205321bdb27988f7c8b92386eb27e11e0dc9dc60d645e8900402);
        s_participants.add(0x183368ed97e69fba36f2efb017999f3b86872000ce920b30418044d7dfbf3a38);
        s_participants.add(0x2762f8f6eaf7b650c899f2570be36adf1008527d579f0e852684579462f4630d);
        s_participants.add(0xb0640dfde8cdf9349e6b3f87e920dccd882df24329446d1e1ac74c8142768513);
        s_participants.add(0xd1e45d09f58ba3e08852f8fb14f49e727a16a3475c082a8035dcd4346d904a2e);
        s_participants.add(0xb69d1869ad1a4ed0d98b681a3c112b1f90a23a0cc9c834f0b16d9271c0b69257);
        s_participants.add(0xde71c7aa758df72f8920ab2a7f4dccd00cc11050d189b2a90bb5276a18a4e797);
        s_participants.add(0x0703757bf69f3e81ca7adceb085fc990de377f0a3dcb41f9c847311c54ff510a);
        s_participants.add(0x14afde140ae72111b15ac739a1e53e09b92e435f50c26fa6f14b8089d2ee119b);
        s_participants.add(0x7f5b0c37437eff1959596b189352ea674bb1bb85a443ae7e98706238d8ee1d64);
        s_participants.add(0xb37cb22035fe7677c96e633d9c906830051a4fb3f0364d28429335c54cf9ac75);
        s_participants.add(0xd2b036e193594871311e82402834bedb0c0bce117ebd95796b76ea1dbbbc977d);
        s_participants.add(0xf0e810890a3399572de9508142f97ccb24018ddbbf1e674e03abeaf975ca0ecb);
        s_participants.add(0xdb3e60e68381c6491cb7ecd9ffdff28a8ae857fa42f5b639382a3ef3c2dc13f0);
        s_participants.add(0x48418b4b13b4c8ca8f6fd63bb88f6f1ef65d178c2c450388f7da5c75ed488e4c);
        s_participants.add(0x2c47834f628f890fef7a3ec34e36ff1904d8de18a044c57b3c9fc4d7c937dd8a);
        s_participants.add(0x8d8f1017e338864e4ea3282aef278fc674c8bba51e3a2cc23a4c8885614f1905);
        s_participants.add(0xdd917fd6826f6f966d6d808eecaff65f2df041648de78fe19972db2ffc503dd4);
        s_participants.add(0x833257b56cf6a58acc9a90b9120ede71df36974d838e3dbadc7ee24d2b148fa6);
        s_participants.add(0xf6d94f0274c646ec0300655dc8e9dc48343a1d2319c64c5fbc3de5b0ebaa1342);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title The Ownable contract.
 * @notice An abstract contract for ownership managment.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipTransferCanceled(address indexed from, address indexed to);

    error CannotSetOwnerToZeroAddress();
    error MustBeProposedOwner();
    error CallerIsNotOwner();
    error CannotTransferToSelf();

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor(address newOwner, address pendingOwner) {
        if (newOwner == address(0)) revert CannotSetOwnerToZeroAddress();

        _owner = newOwner;

        if (pendingOwner != address(0)) _transferOwnership(pendingOwner);
    }

    /**
     * @notice Requests ownership transfer to the new address which needs to accept it.
     *
     * @dev Only owner can call.
     *
     * @param newOwner - address of proposed new owner
     *
     * No return, reverts on error.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Accepts pending ownership transfer request.
     *
     * @dev Only proposed new owner can call.
     *
     * No return, revets on error.
     */
    function acceptOwnership() external {
        if (msg.sender != _pendingOwner) revert MustBeProposedOwner();

        address oldOwner = _owner;
        _owner = msg.sender;
        _pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
     * @notice Cancels ownership request transfer.
     *
     * @dev Only owner can call.
     *
     * No return, reverts on error.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        address oldPendingOwner = _pendingOwner;
        _pendingOwner = address(0);

        emit OwnershipTransferCanceled(msg.sender, oldPendingOwner);
    }

    /**
     * @notice Gets current owner address.
     *
     * @return owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() internal view {
        if (msg.sender != owner()) revert CallerIsNotOwner();
    }

    function _transferOwnership(address newOwner) private {
        if (newOwner == address(0)) revert CannotSetOwnerToZeroAddress();
        if (newOwner == msg.sender) revert CannotTransferToSelf();

        _pendingOwner = newOwner;

        emit OwnershipTransferRequested(msg.sender, newOwner);
    }
}