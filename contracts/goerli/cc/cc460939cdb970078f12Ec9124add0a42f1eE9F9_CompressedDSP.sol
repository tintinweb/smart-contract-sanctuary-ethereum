pragma solidity ^0.8.20;
import "./InflateLib.sol";

contract CompressedDSP {
    bytes public data;

    constructor() {
        data = hex"955c4d731db772fd2b2aadc4aafb58e80f7cbd5416d964955dde2e954ad11463b31e45ca1465d949bdff1e0c80c174033dbc8e5db6e66a80061aa7d1e83e00e6e9e1edc32f8fdfde5e5eff701ffe797ffc74f34f4fc70b387b81672fe8ec059fbdf0672fc2d98b78f6229dbdc8a70a9eab7eaa3b9c2a0fa7dac3a9fa70aa3f9c0e009c8e009c0e019c8e019e8e019ee37f3a06783a06783a06783a06b88ec1e7bbb7bbadc7db9f9f00d3e5035c3e3c3ffcf8f0af4f2f776f84fff2fa7af7c7a7ff800b5c5cfdb73d8dffffe74d97f3f89bfbb0c979fcedc3a70fe59f2266fb3fb6d70fbf7f2dea97f7db432b506bb4b75fef5eefbee0f6ba3e7df8046efba7bdfcefa7979757da5ed6a756b9d710d559542751d35b3559d60ca2661035a35533f49a3f5eefbea6adc0f6d0def7e6aadeee32fe26f61adfbeff94b70ae5cf56be89580bd6b1727ab06ae5f6facbf7a737a863b93d89a6a9c9ead585228093265d84688e7473ad6ba23dbed21e49615e0b53ca6d9221e881eb2d8881eb625a95bbcf9fa162511e84c4a2d565ef2b04a56f9af46d1204e49005e64e1aa1932f6e29f577bfdc7d7b796d16dc9ea5196a3356761c8e3144d26338645e0e4928d5403660433a4605bd1a955db3c3a29095bcb00e0b7a81324603e552ab0afc0b1c0863d208f7ca42523624413a0c0693ec19394bd32c8795400c2b8f21205c8780fa902aff41abee84c268890da32512564bde98eea5e793d9d2f02d2f3fa8b996971fad467382c368c92b05a35010291e834969329c2af8b01a52a64dcab46f73768e883ca4f21fa76ecf2fcf0f5f5f9e1eb88e7bff718c3c25295dfa1d863f6fc39b8a8ceb4c679043d6adaa54fcfab797bfbd3efecc15a9e3f7e19078972c0af3d5c2cddf7b392949c73f5c511ad1905825fce1ba392adf7d94beb9ace587e4744d723143ceca84455d43725934bd5e67bfa93f844ead63adebfdf9fda2ad2f7d3dbffbe99baf609787b15efbddd3fdfce62bb23f773b68a51bacb70e90938b1183731130100a243c49247a5bcf9f7d05b23c347955fea1bedfe7e1ff7cfbf1f876ff8baf70f61fbd0755c6657a1cb1efa71b2d202c029451d5ca4763d29dec7f1b1709876c61df87101d8d7b691a410bd8e7738926aa6dec3e6b6ea09bc4c3d3db5d6846b13d1a7360fb11404fc5bd5a73eeeed677f47c9f630ff78f5f5f1fefef9e4245faf86d99f136afc3b4bef546ab58256d587e6065f95d8804ce0fe0ea4bbfb6c078da4231fd10d4ac6d6d5e46637bf75f5fbe3f7f0e15d1fa3862ae100ce9978fcf0f77af0fdfde3e1e9a24a5c92e6f6da94318f2623d15ec7d1e86743cb200313a0de2216e75a9fb10461096e68f918b4e8017510fada86c78a116d191b16847e576231b61d6c3c3df6373c7e5e9c3a79a80d43686d8a3c5b82bff7457d48c15cdfad88db0c992169386c5ec99728c427f6e15777103c0982c279c76f7defb7e777ffffd4b6cfe7a7b5c3c070dd88ac0cbff7efcf2f8fcf1afeef2f1cbddef1fffca5b4ef30fa14f72efe8a3a48e7e2650fddcc548dcbfbc7c4e0dcd975e6aeff6deb73442ff5f530bfc7fed08d6aa1729f9309134e500b5f25957f7014c5e0c7e3aec24b12ec8295c43a91a44925112dc3a8404e46388048c9965c9a4e2a000991d958239641738aae998d6e968ae959b3a37d2dab66e8b00204561bb492650d9e9c15b6dc66c7033de1bb98ea4b1403ffc9a41626799c2deed8c5750a85da419df0c7a6a6594b331f364bdaa074b9dbade643f2d53bba41174e4a0838e5e6b4c801c973523efb3aed6163335a769a67624f6795064cd73148e29ba15d0a1d92e7406a4167f7e79fbafb26214015b9dfe6b2c3b792f76ff54900757a1abcfad88a8bd7af296d8399958a200021c4d481cd3e8e66c823efc0a8e17fbd944295fb265e6cecf86b155bd0c1fa0a612b835b4daa55c0e5ea83bd42f8fbf836b59e7e3efadf018a063266daacb31dfdae84b7c59911fc0559ceb736fb089152389eba8f6b4075c5e92a021b6c74439497601dc557a016065a3b65260a4ab5be1b3941dc0c85b3729920ab2b899ade292b6c3ccccecf5a5b4604a7382eb01afbb184d7629e8014946d8bfa992ad01496b020f688d3a64c93bcd0ce3a828a82744238bdf7498d92704392c6804b79bac8b9d6f02aac8670faa374115825dcc2e5bd8fa3080ea6da09136c2872da1c9ecc2f01faa236ac1f4e136c4e43de4d291907696a1d93bced368f4404e9ef67fe7649777e3ffedeefeedf5e5091afdd37f75f75255af955aa631da14a34cd32a29a668ad23e44bd368dcd0bb139270b5bf5ed9a49681349ec42bfdd4eb7bbbbe0cdb81826575440b590c243807a0b810c6b0533f53f1c6c2a68535068a6a844d626e67cc7621523fb6b8392035f11856fa78eba82490f16ac3ac1869266b320f7d6b138dfe9989645ce6b28ca081bdc125b31364326b1fcc066f0aacc83be0683b7c4e867fe378eef01b1b3437a6668977d65072361cbe07c3e17ba7a499c07010c078505df456e2b7c99103e2d9e46bc15b9cf54ed72887efad61f7cade1b0933db88977b34e0ad5d9a4d8765bb414d149f0d87effbc274d0a752e5a0f70eca4ccad9798cb9a41e1458080f6066dba4d8c44d9e128f4a7c624a9e6913ce08917550d3c89885d985a0e2aa4195dcff71bf55aa98d567096c564a6fa255b7bcea96734c9c12223a4287acf59e828bd1acec93e494204c5b12fb327139340a5a8734e9706025ea449d7d123442e6c041f42e2975a30639fb44e21fa96c3c011976b6660854f271a2ef8b82c73f71b0c0d0e897f7b65b232f1bae5b2d39c7a2bfba72c6b072384dbf099adfee5e1fef7e7a7af8f4f1f1e3cd9abe449d8fbbec6542d448159110add2dc9298a4c9118e862e472211c72e52ddaa80b4ece1eda26467934421c926cd4dbc4daa8034a1de8db4f6f120c93529f925abddc6572cf42355afc583e144631889ed264ff5201a3027b53ea764eed8456351696cc9b4a828b603b2b944edd4d62e45763183354859c392d15e541a75316f84a2b1a864364622abddeb6c6d5f4356f15c36e3b90ccba232a88baf2f3fa071177a3b30b2083cb24e9a72b292883630d9307d92f4d3565b6cc83ab76c226efd397c62ceaa38ac7e179d6697fae6b77658ae64a7055cc7be3cc404d94ba974cd650c998a54c1465528526517a8d63d6c5cc5b2eee1ce2708814a89a0b7fd29c4d2ff9872c839465087001a5f619c02085aa4048fca42c15402cb6d472c44ce381c3936fe6138f2d3314962e3bf511087c18f9e5dbaa3dfa41ef68a306dfe7419275413c2b408918b9e5d2a807a0ebe9f69782bfd7cfeb98c79e328f69f47b884a0f685156b81336b2100dc49972cd6f57ea8648a4d507117387317b28797b1a21f074b7abf64e8ceb7b120ef3846e74b42c2e9c0a95118577102750e02b2318f201c384192e10b3696630d5fc6b8ec52451b084654b5495a1bd97e340664e8f17af7e3dfbf7ff9b79797af9fe6fd8a7f5c460355d4d094056d808d1a11b4c1f3cbe3b787839e38a293bfc06a6a1351e21c0e66101b573298c1d19c2498b38a9911a77d858c283716f2e007519f7c998fbec8eafbb67640af7a3e05342e474f2e0586fe2014c9d71529d3516b923e4c672bb1d123a2fcd045d903d9816713d095d955d91cc17486661f8fc3dc08d48421d28afb43d146935c5114b4a234ed19957583e4aed1567e5794d47ca7602b5a054853ab5aea8d83aeb85052bb6fd2e8a254f2cfa0899392339ac552159a28945468f2099a55809c8d9b468cab921249d64832990146e903ff192075be8af3e61f10b202920e1d5901c9274056010dc820945c916489246b24394d199bd0f2cf20c9939633928c5e21c9424b85a43f41b20aa82d0401a55fa16409e520655aaffdec85bb8ce6785373c3fd0fcb0ffbd90f03e650d63f2a8e88b2238063d8bcf6cb7d5139585df492d1de44ab96c294e1ee0bfdbed43556e79d0d992147899d8265f0c9274cb14c93a24a5445f3e4c012137359628bdf08cc24c7b5913a625c452f97056ef444fe523630333fa391ee9763f2941304a21cb98c7e0fb5ee9eb1d13fe54978e90022260c3a09ea7524d21b508de319abbf2cd585c89152e40edcc6b2ac9531ca1c0830619e8f0a612378ccb34218bcecac9ec3bd67d3591b0c418d5db2e74fd82768172c5a318fd681df2bec6207e38e8dde39928c66ed877405e6ccf0482dfab32c8de7a52d9db7f622ad4bf37e2467172a4af3e232a2decf15ed34ea6786aa8b91dd9e7c731fa5b9db511f2436683b8cc1189ada6032b48cda0b0775120ce314577731b6fce40cf959cb3f4e9a7dbeffe9e9e5feefd898a2fe4b1b501c859b69279d2f41f42544cf99c979579c211daeb3f347bbebecbd6bdd3eda15ee23295a1dd3e4a621f84c104a6e5962a3e2c3642e91e6946988900eae7149c2c18dca6aad683f7cf3765e1d99d76772ca62c66504b65437977f492cdc49e33cda97eac6e3b8c8dd1fd8a8a6fa7c4cc8749cb2c234afc611b35a8de33847d2c4c933ea60d2877b28d15a928a2afac949496448c28c065d92f94c863765f012c8e6607085d22764f583e40f9df96675e49ce136c490a303005f1ef4a2dcb828b5280f212361cf12bb3c63d73b2f3713302b769d9c5bb769fb1b98e2f104449e0142496b4050b4e4d0a2c676ee6a4853ea915bf74b8e3b6062b52027590c72368b416e3a7dd15bd55b2539957f7d723184ed7cbe2a39c5483eba10cac40a580fbac91e44535bafb40daacf69f5cde4c4b1d84de671c1c2e93574602b8a6b0cc1c0b0969b2f2d75e9a2a3e0b4243cb306a0b336d81a0ea077c1077f0a7e56e02bba8966ba498833c05734d336591282037625492871b6d221993ac473482d96897696699729eeccb86b902a828910cc0e1d6123e92b5084a7c0e11970680287ef0387a7c0a153c0a1020e4f804313389c808b94cbb2c3a984ea2148a9266cf80e6c68c186123694b0d155d8140f4464c2860236d2b0d1296c74061b99b0d1fbb0d1396ca06053740fd1096c64c246f37c8b3e654628b91e8252c1c48ddec18d2cdc48e2461237be8a9b627c884ddc48e0360e1ed41f2b7d4700d22ae40f923f341d448a0e428eb78c9403674ec939ef55d1290e2dcb52993e9e39962c3a65797b8dadc0865807363b968d095a6fa4b15fa28cf6f7e6f2b79fa916524564428d111291c9b8862f8d8fa30265c27c4852a6b7e1e1dd9c8591a4a788f5bd46af039b980294c8265159f3e3ce21f7923acb28439e5c896b72c9797349044567bd158f929789057915c8785ed7662f8e4c909fc83d242fb93db1154c5ee45ee4839582d7da17358e4a53955184789b8a05964869bb5626433d6f4edd9d993941df671b7ded7abcdc3da5e02cf47d5ed10fb0a0efa567d0877a683ed453226f977248d13907515a7a30310d788e6930300d72fa8785b00d8aaf1598ca7c9a828969ad7d51a3a334d50751a5b90613c6f03e8ce10446bdf007056334610c068c7185314818f5a91d9a4eed9439bc6df796f8a0c4f6c14b6f184d18e33b3046034699ef519c607414258c4ec018799ec5315c9bc5035e7591ca348eae8c3aeb5d6c59bdcc93c197c522b900983803c6038189b419b5e5998edd341a55a3568d2ec25c34929921467db88f925e1c935c1c7dc995530ac5b11737cd3191e8371bfdde290b27f8195af8995e5db03364b33364b233eb463e296ac6894e26ab935175b20d5536f86a4ac751234a32d4c92bd346492e7e83816953af51309a2318396117387d9185d46526487226670d5956f18cf32414cb66e09ae9c4066a5fd6435a94f91de582a11c39a1dc7429181d6539c7d029e5c274689172ba7a6871ec3151ced736a9f63d6f76eeca96f9d8516607d7b6a4c7a62c3bbcb6ab3bf636b9f131ef6d8e0eb7c48d84796f9371bbd9eefc428e272799f459b067277d23f85171932504c773f6bad3d2d38788d849e02008c1eaec25bb69a3aa04ec217bccc5156309ca4996057d30d59760a978d61c11389297173db81131ff9f3d2d563c0d8353df8440c34730c0d53d2dee2787e49e1683d8d160e0794f8b81e63d2d6efc8ddcd31aa5ba1035506139c18b5cbc54c96052469a374ab81137f6fd7708b2b369ded3e29d0ad2e2e4d865734f0b59ec69b1246f78226f8eef4489b087077fb37dfea1d137677b5a8c0a4c5c77a98616fd5996a6f3d296ceb5bdf5d63fa35823587ee2867199b69b007b4f8b319cec6931ea6ec7654f8b71f954c1264e56327853c6680c4d6d301b5a26b5e75441160dccb79fba185b3ec12a9ff4dddb6a13a2c672a0802519c0e4e6d890497a61245171dcea6d9b56dc78206bb30c516f963169163ce612cdb8442eba5c56c4e3740677be47ec951dc371342bdc122990c9a206b6ddaf663cb7206231a6641c2fe47177aab9b4c6fbccc11853b2b6caf62b728072b38c59b1e39c906fa164da299415d3e371fe8319d6cdb2ad0742df4103d500811b11a437cb988e508d07dd33a0615608a3883778dc68dcbf05c1cc57be24511bf1e786df219cbe63c7ea033cc807dcfa9215b3a6059c60f198ad1c92399ec773ccc614dd091d239e63ef8c780e9d18df3984c8ec557c94e5f87aa7bf50a4ae77a397ca997c0eefa77b4ce5bce1653dbda39c379463a1dc9c0f96b8c22bdc402937858a8e7dbc9693d656ccef70d4da1795b1aba1d36192f77e3beb58666f19ff2cce6172a771e4ee7b16f3c3eb4f2ee94682e6e960bb3e8b5072c0ec014466c1c1ca2e39fc89702818e190fc5e0e87351c0a6b3814d6702888704867eb1c823ae2e3a1849625d7cf0425dcdccf3f8b4531bc130ec9b32b1cd67028aca14150e150380987e4111f0e321c8a7638a48ef87090e1505cc2210ec2ced56771d838b433b4e8cfb2349d97b674aeed191335ca7028ca7028aee1503c0d87e269381475b78d7028aee15054e150b4c2a1188da1a90d1abe364ee1903ee2c3c90887623e919f8c7068fa14097a150ea5351c4a321c4a7338e439a9c552e483494ed2c4e7aa761da68fb2b2fa4a0e8a7c30e9b99a74ea12b7cfab51a0eda26974fb09827ec5851bf7a3eecc0c297298d33b372ce59d45d5916c9f8ede04ce77bff656846b55e770783e87231438e0d037c1581fc5b92d39410a61bb71ead105ceaa2869079733b9b4e57a2e798c24a3c0ccd689291ef7c35a4fbc71dd827722c8dd06f1653fe39e1e6739b90705b42b9da3f5f918d637c378ba19c6ea12aaba86cae64d31ce497a18e983fd7c534cf44cf45bd9839f4fe7e4e0b2034fe5a144f7fb01b82ec9372268b54cef404ba5e9bc8cd652f6d962f3fc7e0aa7c7c1b2bc3775f44e60e3f51d313f9dc98925dd0865f52f8b0b6c1f3a9c548c672a062d540399bcec6436954ac6f9b45a1edc8952512a950f57e5c1f09af2f498774efe105790bca280fc4c01ed53f672e2753c9055e1207e0f836fc5792dee9d4cfe0edb6915bc5521ab0a418ec47aa8ce83340620f983e58f6d0abf3ebc7d7f7d9ebede5537627446be9f81959b2aea2f2abfadea5452587963ca69baa240591f67ad1caebe5dc40ea66b38ec70bab3c26ebee1c18ea773b21b2baa4fe6b29bba53cf602a1d6aa27999bea47699be42aabed8e9b5cc9a7c5ea62fa369328527118dbf501dabf9982a5393181d2570a2292ee1bdb31dde97ef6f5fbf1f51c9368d2eae859bcbab221d6e6e6efe0f";
    }

    function uncompress()
        external
        view
        returns (string memory)
    {
        (InflateLib.ErrorCode err, bytes memory mem) = InflateLib.puff(data, 24607);

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