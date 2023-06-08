pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"955c5b8f1db791fe2b033d6980e301ebc25b160990973ce56df3162c16c7a3597b90d11c7934b2ac0dfcdfc3e6adab48f61cd986ad3e6ab2c8aaaf58ac0bd94f0faf373f3f7e7ebdbc7c33377f6e8fef6fffeb697f01472ff0e8051dbde0a317f6e8853b7ae18f5e84a317f190c163d60f798743e6e1907b38641f0ef9874301c0a104e050047028033c94011ee37f28033c94011eca000f6580b30c3e9c5fcfdb8cb73fdf0386d30d9c6e9e1fbedefcede9727e25fcebcbcbf9dbfb7fc2094e26ff5b9efaffffe7b6d279fcd5dc6c741e7fbd797f93fe4964b6ff6379fdf0dba7c47e7abf3d9406b94779fbe9fc72fe88dbebfc74f31eccf64f79f97f4f97cb0b6d2ff353e95c7b88ee2cba93e869573d59f674a2a7133dfdaaa7ab3dbfbe9c3f85adc1f650ded7e132dfe6d4ffc6d71e9fbffc18b70ee9cfd2be90981b6659192dacdcb9bcfef8e5e915b22cb7273134155ab5bb600470e0a49210c3911eae4c4d8cc757c62349cc6a628ab98d32382db83a82105c2553ba9c3f7c808c457a10141357a73657708adf30f05b2808c8210acc8d5442235fdc51a8ef7e3e7fbebc140d2ecf520db51a2b3d76bb0c91b40c3bcdd34e09251bc80bd89076a9a05552699ced1a85ace8b9592c6805cae81728a75e99e00fb0238c41235c3b0b4a714109c2ae3018e4ccc8ac388d52ac0442acdc4540388b80aa4895fda0997742a1b4c40ba525125a4b76b1dcd3cc07b5a56e5b2e5fa99896cbd7d2a318c1aeb46415835e3088e477615218142713deb586946a9352edbb188d21220b21fdc7a1eaf3e5f9e1d3e5e981b3dceb8f5df2142475697718be5f87371619e795ce204556b52a75fcf48fcb3f5e1e7fe28cd4fe7b3748dc288bc67cb571b1f7562e4ad2fe0f6794ba37247609bb9b6ef6ca76efad6f4f73fb4e395ca39cd490a35261d17741396d9a56efb39fd51f82a732b132f5fafc76d33297ba9f9f7ffc6c33d8e9a1efd7b659ba9f5e6d46f6a7aa07a57581f5ce007230dea333c6033a4281842589441debf983cd40a687422fd3dfd9b76d1dfeffe7af8faff73fdb0c67fd516790699c86c7eefbbebfd504dc44402955eebc0f26cd49fb5b3f51d8690bfdde89686fdc4ad5709a405bcfc99bc8bad16cd63840558987a7d7b32b4ab13d2ed6c0f6c3815e8aad5b31eee6ce56f46c5d630ff78f9f5e1eefcf4f2e23bdff5ea9f1b6aeddb0bfd541335945ad6bbe63a5f9958804ce76e0f24b3b8fc0783842527de7d4aa2d639efa606dfa2f972fcf1f5c46343f769fcbb905f5d3bbe787f3cbc3e7d7773b274171d2e8cd2355085d9cb42783ddd6a10bfb230b10bdd120eee46693da44e841689add25e78d00cfa316ade8bcb042c5a3a3c5a6ed95d9f5bc70b31e1efee58b394e4f37ef730092c7e864f7117d63fee99cd8f419cdfc5895b0d0921a13bac6b448d97bc13f978e8d5c07d08795110ecdbcd7b99fefefbf7cf4c55e6f8f93e5a00e5b2278faf7bb8f8fcfeffe644eef3e9e7f7bf727de629adf053fc1bcc18fa2dae71940cdb39191b87fbc7c0805cd4b6dd5a6dde616baebff4b288eff2f15c1dcf52429ef2a12861820773e9a6a1360b042f861d793c0ba2107770da5ac10417a497067100290f5ce133046962d83f2831c4436941a46178d63af96639897e372afdcd8b995dab64d5b3800c10bdd0d32808a460b6fd699e5809bf2deca7d24f40dfae1970812bb952ab46947bc82429e228df846d04b2ba25c8d9107ed553398fae4fd26da619b6a94bad3119d763a6aafbe00a29ff68cd8565dee2d566a0cc34aad48b47590688d6b14f625ba35d0ae59233a02929b3f5f5eff37ed1889c0d6a7feeadb4e6ccdee9f12f2603274f9b93411bd674b5e023b23034b144080a101897d19dd1e2dd0875fc0f0a43f1b29654bb6c8dcd85131b6aea76e03d4520233bb568dca69cf0b5583faf1f1373025ea7cfcad34ee02da57d2c6ba94f93646dde2d38efc0026e39c9feb8085ac9024ce52ad610f983805419d6cf5896290d9053057d30b0073366a6b058b70756b7c14b2032ce2d68d8a4c05ad72335bc7296c873133d3fa4b6a6e49cd885c0f583d45bfcc2e392d90b070fb3756e24a20610ee00157528728f34e6386b17714a927c44514bff130669f10a45870e1dc6eb44eeb781350793ecda9de0865081a99465be87a57806c6da0246d840d9b5c93d184e1ef6a226ac3b4eecef9602dc43411175a96a1e83b8ecba8cf402e9ef27f63e4949bf2ff7abe7f7db93c4149ffd45fd5bc64d673a71269f431859469d825c512cd7d047da91a2537f4e682249cf5af765ea69681349ec473faa9f6b7ebfed26d07722bad239a92c54022e700e4a78431b4d4cfd0bc6461c3943506f24ac2cbc45ccb983522923f5ee5e680d4c26398d3c7db44650219af0ecc2a23cdb45acc9ddf3c4449ff8c89649cd6b2f4a081ed2297cc46249359db605ee44d8155f20ed8af0d3e87857d637f6cf04b36681c4cad126b56a2e4b830f8161606df1a456d090c3b018c053545bb0afc363a52209697f95ab0ab9c754bd728836f5762b74adf4b1266d4112b6b346057559a8d87a9dca0168a8d0b836febc6b4a74f25cb4ed70ed24a8ad158f431851ee4581077b08cb6496513377a8a3c2af2812958a68d382378d64e4d49c64c995d70caafeaa992fb6ff75ba78c597e96c046c5f4465a4dcbaa6919c3c42120a22134c89aefc1b9e8c3ca39c99c12b8a124d1b689d3ce91d33c8481871d2bd1c7ebe893a02464761cc4ec8262d76b90a30d24fe91ccfa0390a1656b3a41451f87f47d6270ffc7f72c3094f44b4f03bf9cbffef7978f7fbf5c3ebd1fd30ebf9f6ede3fdedefcf92f37ffce69962be5dad6e4b864db5a1c966d5b83b74bb78acc50be55140e4bb88ac250c655140e4bb9add51f2be7b65edf55d255f25c97755b93ef2eed2ae68ecbbb6ae88312af1afb7bcabc8ae851a957caf50f947b5bb7ef2df96a391c957d959a8ca55fc93f0e3beb638b17b5c683b678d1ee0d72f45a620c11dd3feae8530d395685eb08a71e0ba35a2ba5e0c66321ba9786f54ca56d0ec3c06e59ca93b618ed28625cc57ae8347218a6140d1ae9f1f8a17d3c2e631772a34559848238ae235aae23b33b49528f4b78a0fd248291225d296a134e335d95f069c289ac769684704ae43014b8f78a941ecd2f8adc6e58b2638cd07aea355be284b1d83d2d5a92d87cba7c2dc1c261c13b4e561fc6a2b77e8d63142df1e0d5d26155b0c00142e6a9942e1d03a6b1bd9ddd8f561e1ccd023b6d1600102118b6e9c10788e3ecfdcad6344a7bdb9a192c81844a2b562a7bd3e6eac4a5efc7556b768203037638fb42cea7b9fb105d8cdec36884ecfa348c9d3c042b51a4e43231a5106bab0d3bcf51781c5b85597b35422816b5d5b0ba78d8e7746ab56a1a54da0ee7370a8db5652e236a4023196fd98484a66567858bf1faf2787efee9e9a18423edd7becdb60a72a3aa15c18665d2a3c5739b0f28f697cd272db1c9e0a7db713377c366266679eaeead9d96a453076dee7cd201c3de1b9be2730e0aac1291acc072a3ed1c8bc375820d2c27c1cd139b6291412c95e8308a5dc4172dbc90c3dcbc3cbc7e79796e9d7ecf0dde3dbe2be117cbac58a9618aacd8f3e5f1f3c39e7ddb9de71f604edafb313ac23df15dca993df1dd8793f593a843423f1c2388a0aa9b714f7f7b957df161198be4eeedd48643ab661e8799476fc904c7501f76464a1df36d4692dbaa398937c3d16108b250bdb56fbca832248475a9ba10a8cc3456360fb09438953bb2c9638f0683ce5c049dba3556306abf8351d08c8e954e0050b5cead7d6754c5bec1af19cd04a4aa652eb5d35519174cea7c68d0e8a260327e0f9a383039a28910159ab83319159af100cd4c40aec68da348339312c9a8918ccb247c9ec3f70039a463e2082441544092e05101190f80cc040a904e3039231925927138c93a9cf7dbb944f33d48f2c0e58824a3514872e772a32f8e7c9a032433813c82dba14433431905941b356185d18c56b8d228863714335cff58d86134a31d068c2eed678418281a021062d376b9265bf6a2051a152419950946e38704ceb67d0bef0c4bb5f28d7a63a7a3c86a982dd86003068fbcb1e265533083010b4c9c50b048d63193946bc93608b98a594e1b5c9f89f8054a0760d0813e48b5cb3e588a011c51f49ca45fbabe9e9f6b7a223d89a011c4593104edefd53e12e904544d48749744b6aa4494a49c3a4de2d3b6966414d91160c0389e84c39293581e85437072b27a0dd7990d47c910d4916988ebf5e3da02ad84f7514aba623cb404b67568647b41094bea628f208ab677eaa8c0c4014cc9457d96ade9b8f58ae73cde7c00105b51b51115aded68321059698018a7a43746a82a1939edc13657298dd346a73a85d99bdd28cda2c903c60597415b61a70e3ae25808ad64d6f40966faa48fe1c07e90f2c3fd8f4f97fb7fd59447fda515c8f7c645b5899441495e68d2aa18998c35688976d359f21ddd74d6d99569efe30af341aa9880349869703612b8143026d2c986894c3f96cc8888103a0969e06a09753770bdb3da2bca0f5bac9d553742481d5d406b3849608b5f63fa979cc041e3dcc797ec86fd34d4f91b723bb57bfeb62fc89665a92487ab6ac86a37f6fd985421277468acb8f6fac2498c2419659a4f6b164abcca51b2b6bef52fed110db7a461474716d92fdc75103681a58160963f9ce6470297e476e7bc8bde24ffd9a607bd292f72269d480fc3a3c4ce8ed8d5c9cb5ad94656cec8c27c0aa1bec1c11f0f406419c099b4828210a45d268cadba82d16bb16d1e2559a2d8dbaf38cadda29fb42fbfec3235812d6ff283e661c89784f4af0dc63bb75d3f512d071fc97ae35c5a580ef3394e3983b0e4d6296ed5363a166e1b238247b9873abd87766c45738da15b6058b2e038dbec96e2e85d15253ad206c74763d895381cbf097ea9ba2ec18f0a7c557ac5b1f42ac82dc07761707b43720d814d5a02c9cf563cc4250fe118526f1690cae3f51bcd1d520fd7205547dfd1e37242c26df41a387f089c3f02ce2f81f36f03e70f8143a380f3fa16df01707e099c1f80f31431040ec95577f2f6a25fc2e6df802dac60f312362f610b57615379200c4bd8bc802d68d8c2216ce108b6b0842dbc0d5b38860d146c2add83e100b6b0842d8cebcddb1039c5074c088a85256ee10ddce20ab720710b12b778153795f1c1b8c42d08dc2248f273fa6e33b54289e48f207fe87410aa7450daaaef38f9578e2387608cb5aae9e087a66d89d226c2ec53141da297ec2c1d9ba81d9b8665c9044da5196c7920e16594bf5f6e7f91b597d1334245f62523243c93fe9509a97c519e29233360de2929d5dbea8906a6284ca6a7c8a8f32c64b463e38383e4d9044a7bbe6f39e4da52471949e4c1246a3159fa984096935df9a3646460b151933decb437930139eb21b997022899db93656123622f327e1582e7de272547c5a98a289cbf0b490393a7b4dd9a0c72d671c967780b7d02b3465f999e8db418683c73d2294de80f07d8ab0876ba00fad2b6c63424cfdb84e88237c6808f720a4b4c818e318505a680722e73c256e56b65a95f620a4b4c73ef93928ee254616aa5bac21246781b463c80516dfc040a465cc2880b18718611248ca861c40146075b0d37f907c9b777565e55c7258cf8068cb88051e6800807180da184d10818d18eab18fdb555dce1c5704d392a3351adde2073af446650f8b45904e320f90c11d0ef080c499bde5b9e83adaa412555a3768d4a62b56910d112037d8c93f401775207dc6d8a954370c4691ff3ec038979dbd5bcf5f9dd9c62a1293f53bb8bec0cadb333b4cccecc57a248a5668c98645c4d52df2ac9a262b3c85753cbd954523b5d9e336d4472f3eb1998b2f44a0a66c811b8fd021af523ef3d1aa7928511d1f9be92f51d1362e5cf184b92b195e34acc073a90e7e266e6d8bec19c5f30d74ab095e0f06524521f4440a3981bcfe4125f3f93db6b4c54d2316f15a95acd9b2c5c2999f78a3259bc5692ee4559b274adaadb6b9b54f2316f1547bb59226baf151937615b37b96524b3663412b664a56d04bb2f52eb24e1709cbdae69e9e13b5b642570e0046175969a8603f3493dc0459bdc49ef3139e5a4daea439736394bc9b2468fc09eacbcc7442511f3476a5aa4f234e4e4d52f1a8faef441aed5b4a8a471544d8b9ca86890b3634d8b1c8f352d2af91b59d3eaad2a1125283f1d5047a690b48142441a0b25541237cb9a16392f271bc79a16cd9f4720a7c28a3173b37fbb6caf69914cded090bcd93f8326dd9e9ebff9fce5472ae99ba39a167905a69fab549d8bfa2c5bf371eb15cf793c3b9b512ff788fe4d83dc7a5ab6e4ed414d8bbc3fa86991d7d30e534d8bfcf49d8c8d9cecb4c89b524bef28d16c0306b3e032aa9a5306597ec50866472f9823fa38d30ffa3a7ad609d1633a50403219400146df9082b4c248a2635ba4b56845250fb42a9621ea6219059d05f731753621454926a6a0773f9d41c18fb5b25d1cfbb0c22c05057258a606dad160b803e98b85d58941ea5f282826ade47d26672cc455a9acdd000534eae3532a3bce01f92eed8c26b8b44f5814dfed8a3817cb282a33dcd340c5412889205d2ca3205cb59eeee9d0505408a3f437e2f0a98a64c4ed950fa5e441dcb1e2570887cf3452543108ef7047a73fdca5d3024664f1282e63c8188efd39368b251ae3a13fc725b133f8737ef7e778f4a4b62f6a28ff280af96ee4e407b8547607d10ae67899cfe176ba67cddc6c65d9f01bccb90573513237868ec046e1068ab9c155346cc2b598348fb2fcd657ee7d5211bb14dd709ec75a0b06539ce023db28ce61724de3c8ea3b7bc1a23cb8c3300ca2f374b0dd0e47483160b40024bf00b73e757fdd1d6298dd2106e10e314cee10c3e40e314cee506f558928bef407636caea027d151f2ee99c3b8c7321cbb432ccfae304cee10c3e41a30487788f1c01d92477c18843bc4b87687d4111f46e10e314eee1083d073f559035e1cdae95cd467d99a8f5baf78cee32d162a0a77889165ebc91d623c7287188fdc21463dedd91d629cdc21561fb0645cb8438c61219a6d40320b2e0777481ff1619add212673447f7687980677c84a77886972879850de7419dd21cba4364b2b3aca454af698d5cac3f0cd6126954a7782b05eaba44317bf7d3d30054cdb3d6a6fda0982767d85e60b319d8a14737ce302b1bc922b27c2667d3a3adffe8185629032adea1c0e8fe77004033b1cac774b7d14e72e2d92e0dc76a1daa6d886a36acadac0c548266cb19e09163d092f904b52683c31c5cc6abaab3bdadc1241e66e3ff0c4c3519d3e75c196d35f47e2c535a64a49f1a40fbbb2ba63ad6e59f3f831844ee02457adec006b3858c261f5e6389ece89ce440396d243f2d1db01b846a92482169a69876f92f2705e467329e7bccae6713b8553fd60d9dead79b4121bab17df7026c7a7c5e9d2eecf2ec2f61dcf81c5a3c5673590560319e442724be4dad706d4f9b4d2fe00382b8173c25767b7b09af2f4185b903f9ca4a3b6c9d5ed25d6370db5d571bce860f7c4efaef0a5f9ea9aa1ba35b6eb4ee9e0161d54126b47224b623e54c74e2a83fc2ce6361df1635bc2f5ba94fe385d2ec4e888bc9d81954515f51739bfadfae4a4b0b2c6c471b8a240561bec9cc3d5b78ba87d30562564f59d15b2e30d0fb27638274b766021a733d5dfe433988a871c689e860f059e868fecaa0fd25acd730e3e4fc387ff7432650b23b5b0290cece4784cb5c9418cf6129878f04bb8955b2abc972faf9fbe08af644b759ae26e4eaf1275b8bdbdfd0f";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 25342);

        if (err == InflateLib.ErrorCode.ERR_NONE) {
            return string(mem);
        }
        return "";
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
library InflateLib {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Bit accumulator (can use up to 20 bits)
        uint256 val;

        // Load at least need bits into val
        val = s.bitbuf;
        while (s.bitcnt < need) {
            if (s.incnt == s.input.length) {
                // Out of input
                return (ErrorCode.ERR_NOT_TERMINATED, 0);
            }

            // Load eight bits
            val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
            s.bitcnt += 8;
        }

        // Drop need bits and update buffer, always zero to seven bits left
        s.bitbuf = val >> need;
        s.bitcnt -= need;

        // Return need bits, zeroing the bits above that
        uint256 ret = (val & ((1 << need) - 1));
        return (ErrorCode.ERR_NONE, ret);
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        // Length of stored block
        uint256 len;

        // Discard leftover bits from current byte (assumes s.bitcnt < 8)
        s.bitbuf = 0;
        s.bitcnt = 0;

        // Get length and check against its one's complement
        if (s.incnt + 4 > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        len = uint256(uint8(s.input[s.incnt++]));
        len |= uint256(uint8(s.input[s.incnt++])) << 8;

        if (
            uint8(s.input[s.incnt++]) != (~len & 0xFF) ||
            uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)
        ) {
            // Didn't match complement!
            return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
        }

        // Copy len bytes from in to out
        if (s.incnt + len > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        if (s.outcnt + len > s.output.length) {
            // Not enough output space
            return ErrorCode.ERR_OUTPUT_EXHAUSTED;
        }
        while (len != 0) {
            // Note: Solidity reverts on underflow, so we decrement here
            len -= 1;
            s.output[s.outcnt++] = s.input[s.incnt++];
        }

        // Done with a valid stored block
        return ErrorCode.ERR_NONE;
    }

    function _decode(State memory s, Huffman memory h)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Current number of bits in code
        uint256 len;
        // Len bits being decoded
        uint256 code = 0;
        // First code of length len
        uint256 first = 0;
        // Number of codes of length len
        uint256 count;
        // Index of first code of length len in symbol table
        uint256 index = 0;
        // Error code
        ErrorCode err;

        for (len = 1; len <= MAXBITS; len++) {
            // Get next bit
            uint256 tempCode;
            (err, tempCode) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, 0);
            }
            code |= tempCode;
            count = h.counts[len];

            // If length len, return symbol
            if (code < first + count) {
                return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
            }
            // Else update for next length
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
        }

        // Ran out of codes
        return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        // Current symbol when stepping through lengths[]
        uint256 symbol;
        // Current length when stepping through h.counts[]
        uint256 len;
        // Number of possible codes left of current length
        uint256 left;
        // Offsets in symbol table for each length
        uint256[MAXBITS + 1] memory offs;

        // Count number of codes of each length
        for (len = 0; len <= MAXBITS; len++) {
            h.counts[len] = 0;
        }
        for (symbol = 0; symbol < n; symbol++) {
            // Assumes lengths are within bounds
            h.counts[lengths[start + symbol]]++;
        }
        // No codes!
        if (h.counts[0] == n) {
            // Complete, but decode() will fail
            return (ErrorCode.ERR_NONE);
        }

        // Check for an over-subscribed or incomplete set of lengths

        // One possible code of zero length
        left = 1;

        for (len = 1; len <= MAXBITS; len++) {
            // One more bit, double codes left
            left <<= 1;
            if (left < h.counts[len]) {
                // Over-subscribed--return error
                return ErrorCode.ERR_CONSTRUCT;
            }
            // Deduct count from possible codes

            left -= h.counts[len];
        }

        // Generate offsets into symbol table for each length for sorting
        offs[1] = 0;
        for (len = 1; len < MAXBITS; len++) {
            offs[len + 1] = offs[len] + h.counts[len];
        }

        // Put symbols in table sorted by length, by symbol order within each length
        for (symbol = 0; symbol < n; symbol++) {
            if (lengths[start + symbol] != 0) {
                h.symbols[offs[lengths[start + symbol]]++] = symbol;
            }
        }

        // Left > 0 means incomplete
        return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
    }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure returns (ErrorCode) {
        // Decoded symbol
        uint256 symbol;
        // Length for copy
        uint256 len;
        // Distance for copy
        uint256 dist;
        // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
        // Size base for length codes 257..285
        uint16[29] memory lens =
            [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258
            ];
        // Extra bits for length codes 257..285
        uint8[29] memory lext =
            [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0
            ];
        // Offset base for distance codes 0..29
        uint16[30] memory dists =
            [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577
            ];
        // Extra bits for distance codes 0..29
        uint8[30] memory dext =
            [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];
        // Error code
        ErrorCode err;

        // Decode literals and length/distance pairs
        while (symbol != 256) {
            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return err;
            }

            if (symbol < 256) {
                // Literal: symbol is the byte
                // Write out the literal
                if (s.outcnt == s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                s.output[s.outcnt] = bytes1(uint8(symbol));
                s.outcnt++;
            } else if (symbol > 256) {
                uint256 tempBits;
                // Length
                // Get and compute length
                symbol -= 257;
                if (symbol >= 29) {
                    // Invalid fixed code
                    return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                }

                (err, tempBits) = bits(s, lext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                len = lens[symbol] + tempBits;

                // Get and check distance
                (err, symbol) = _decode(s, distcode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return err;
                }
                (err, tempBits) = bits(s, dext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                dist = dists[symbol] + tempBits;
                if (dist > s.outcnt) {
                    // Distance too far back
                    return ErrorCode.ERR_DISTANCE_TOO_FAR;
                }

                // Copy length bytes from distance bytes back
                if (s.outcnt + len > s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                while (len != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    len -= 1;
                    s.output[s.outcnt] = s.output[s.outcnt - dist];
                    s.outcnt++;
                }
            } else {
                s.outcnt += len;
            }
        }

        // Done with a valid fixed or dynamic block
        return ErrorCode.ERR_NONE;
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        // Build fixed Huffman tables
        // TODO this is all a compile-time constant
        uint256 symbol;
        uint256[] memory lengths = new uint256[](FIXLCODES);

        // Literal/length table
        for (symbol = 0; symbol < 144; symbol++) {
            lengths[symbol] = 8;
        }
        for (; symbol < 256; symbol++) {
            lengths[symbol] = 9;
        }
        for (; symbol < 280; symbol++) {
            lengths[symbol] = 7;
        }
        for (; symbol < FIXLCODES; symbol++) {
            lengths[symbol] = 8;
        }

        _construct(s.lencode, lengths, FIXLCODES, 0);

        // Distance table
        for (symbol = 0; symbol < MAXDCODES; symbol++) {
            lengths[symbol] = 5;
        }

        _construct(s.distcode, lengths, MAXDCODES, 0);

        return ErrorCode.ERR_NONE;
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        // Decode data until end-of-block code
        return _codes(s, s.lencode, s.distcode);
    }

    function _build_dynamic_lengths(State memory s)
        private
        pure
        returns (ErrorCode, uint256[] memory)
    {
        uint256 ncode;
        // Index of lengths[]
        uint256 index;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Error code
        ErrorCode err;
        // Permutation of code length codes
        uint8[19] memory order =
            [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

        (err, ncode) = bits(s, 4);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lengths);
        }
        ncode += 4;

        // Read code length code lengths (really), missing lengths are zero
        for (index = 0; index < ncode; index++) {
            (err, lengths[order[index]]) = bits(s, 3);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lengths);
            }
        }
        for (; index < 19; index++) {
            lengths[order[index]] = 0;
        }

        return (ErrorCode.ERR_NONE, lengths);
    }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            ErrorCode,
            Huffman memory,
            Huffman memory
        )
    {
        // Number of lengths in descriptor
        uint256 nlen;
        uint256 ndist;
        // Index of lengths[]
        uint256 index;
        // Error code
        ErrorCode err;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Length and distance codes
        Huffman memory lencode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
        Huffman memory distcode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
        uint256 tempBits;

        // Get number of lengths in each table, check lengths
        (err, nlen) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        nlen += 257;
        (err, ndist) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        ndist += 1;

        if (nlen > MAXLCODES || ndist > MAXDCODES) {
            // Bad counts
            return (
                ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES,
                lencode,
                distcode
            );
        }

        (err, lengths) = _build_dynamic_lengths(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }

        // Build huffman table for code lengths codes (use lencode temporarily)
        err = _construct(lencode, lengths, 19, 0);
        if (err != ErrorCode.ERR_NONE) {
            // Require complete code set here
            return (
                ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE,
                lencode,
                distcode
            );
        }

        // Read length/literal and distance code length tables
        index = 0;
        while (index < nlen + ndist) {
            // Decoded value
            uint256 symbol;
            // Last length to repeat
            uint256 len;

            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return (err, lencode, distcode);
            }

            if (symbol < 16) {
                // Length in 0..15
                lengths[index++] = symbol;
            } else {
                // Repeat instruction
                // Assume repeating zeros
                len = 0;
                if (symbol == 16) {
                    // Repeat last length 3..6 times
                    if (index == 0) {
                        // No last length!
                        return (
                            ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH,
                            lencode,
                            distcode
                        );
                    }
                    // Last length
                    len = lengths[index - 1];
                    (err, tempBits) = bits(s, 2);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else if (symbol == 17) {
                    // Repeat zero 3..10 times
                    (err, tempBits) = bits(s, 3);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else {
                    // == 18, repeat zero 11..138 times
                    (err, tempBits) = bits(s, 7);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 11 + tempBits;
                }

                if (index + symbol > nlen + ndist) {
                    // Too many lengths!
                    return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                }
                while (symbol != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    symbol -= 1;

                    // Repeat last or zero symbol times
                    lengths[index++] = len;
                }
            }
        }

        // Check for end-of-block code -- there better be one!
        if (lengths[256] == 0) {
            return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
        }

        // Build huffman table for literal/length codes
        err = _construct(lencode, lengths, nlen, 0);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                nlen != lencode.counts[0] + lencode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        // Build huffman table for distance codes
        err = _construct(distcode, lengths, ndist, nlen);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                ndist != distcode.counts[0] + distcode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        return (ErrorCode.ERR_NONE, lencode, distcode);
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        // Length and distance codes
        Huffman memory lencode;
        Huffman memory distcode;
        // Error code
        ErrorCode err;

        (err, lencode, distcode) = _build_dynamic(s);
        if (err != ErrorCode.ERR_NONE) {
            return err;
        }

        // Decode data until end-of-block code
        return _codes(s, lencode, distcode);
    }

    function puff(bytes memory source, uint256 destlen)
        internal
        pure
        returns (ErrorCode, bytes memory)
    {
        // Input/output state
        State memory s =
            State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
        // Temp: last bit
        uint256 last;
        // Temp: block type bit
        uint256 t;
        // Error code
        ErrorCode err;

        // Build fixed Huffman tables
        err = _build_fixed(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
        }

        // Process blocks until last block or error
        while (last == 0) {
            // One if last block
            (err, last) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Block type 0..3
            (err, t) = bits(s, 2);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            err = (
                t == 0
                    ? _stored(s)
                    : (
                        t == 1
                            ? _fixed(s)
                            : (
                                t == 2
                                    ? _dynamic(s)
                                    : ErrorCode.ERR_INVALID_BLOCK_TYPE
                            )
                    )
            );
            // type == 3, invalid

            if (err != ErrorCode.ERR_NONE) {
                // Return with error
                break;
            }
        }

        return (err, s.output);
    }
}