// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

/**
 * @notice Generic compressed data.
 * @param uncompressedSize Used for checking correct decompression
 * @param data The compressed data blob.
 */
struct Compressed {
    uint256 uncompressedSize;
    bytes data;
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {Compressed} from "solidify-contracts/Compressed.sol";

/**
 * @notice BucketStorage is used to store a list of compressed buckets in
 * contract code.
 */
interface IBucketStorage {
    /**
     * @notice Thrown if a non-existant bucket should be accessed.
     */
    error InvalidBucketIndex();

    /**
     * @notice Returns the compressed bucket with given index.
     * @param bucketIndex The index of the bucket in the storage.
     * @dev Reverts if the index is out-of-range.
     */
    function getBucket(uint256 bucketIndex)
        external
        pure
        returns (Compressed memory);

    function numBuckets() external pure returns (uint256);

    function numFields() external pure returns (uint256);

    function numFieldsPerBucket() external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {
    IBucketStorage, Compressed
} from "solidify-contracts/IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract ExtraBackgrounds001BucketStorage0 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 9;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 9;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"010101010101010101";

        uint256[] memory num = new uint[](9);
        for (uint256 i; i < 9;) {
            num[i] = uint8(num_[i]);
            unchecked {
                ++i;
            }
        }
        return num;
    }

    /**
     * @notice Returns the bucket with a given index.
     * @dev Reverts if the index is out-of-bounds.
     */
    function getBucket(uint256 idx) external pure returns (Compressed memory) {
        if (idx == 0) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"d494416e42310c44bf7a1cceda2567e10ebd02ea1a0ed01daa940aa544493c76c64ee08b2f6fea267ee3b1c3f6b16ddbe19094eff7e75bcb6bff5af541444e76b12ffd491abab206faa9025ee3b6578c777601d943c3a1184d21d4631c36589a00db1c28d8c88423409f0179e9da4568f2ed7a72d18d51d66bc9f778bb9e0c0db6ffae5b9292d15280574f40408dae05403dae0dd16c91443b18373a7a7d9219904b866b8b6cba4490ac5c536ecbf07ac0f640b52573772dbf7d5e564ee7630e7ef7607df864e0d24a743a1f2f2975c44b4a32695bcacc42d233a866958c14e0da5e2d241a06b309ccf2a4af4f1b1dfe1592f53501f768c7edeaba2bd5a15d62b42035fcf7d2ca50dd46678c65b3e7ce3cd8a13c7be5280708fa0cba04a4dce90851925003f3dc3ab46cb3f6b6d46f92d58697bbe46387744c7105f7e800fae1f3b8eb45028668486ffe6cfdcf236004c88b5ac1f9a0b8a26baaf8c8ffc8f5614deff919ee4cac9a208f7897a65eaf21b657bb74f788bf000000ffff"
            });
        }

        if (idx == 1) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc984b6ec4200c86a3963b64c1228aba9bd3e744b9440fd02e2c5996c13f1e83d38e584491c3e73766b68f6ddb5eafefafcfd475d572d5729f85dfdc67a1d595cca04b05bae8d445382774c603ce6f598c1f8eba672fa0db03f4a3eeadffe9cd5fd14981ff431fd68555b6c39d3d71c73b0f15033b63fa558be59ff06a3ddf5ac7f4305a7dc888d6768bce32f3e6037adb0341742635513b73cf911ec0f41905b0ed9ecc0cd3e98c7babe2320efa77e9437b870254411ebb3cfe8965fe907e9f3a3a0b87100f5d8ab1d366cadc43f7545c1e3d35e7877d6c09dd8ad112baa7f4808c27ebc0ece71f2470217b6c5f7ea790e56c5d5bf0e815e8f9b29a141dd80e1081164486331d47879a8ce5fc18fda8fb8ff839a72fd67cf95c078e6099999c21b1ae4bdf2adbe55624e0ac8b58b3555739395979cec136dc78da67797a50b6b7f4ee4ccbe9aa3c93718d7de612d74de3c76e91dda82da75bc15ad2b7551eca24095f3fa5006877dd2a20ae2ca2c9c3c21200dd6fd8182de51ffe0fed3ecb6f000000ffff"
            });
        }

        if (idx == 2) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc98c16dc5300886a32e91430eb9bf3db243eedd286364838e91413242d51e9010c2e6370f9bb44f3e4411f1071830bce9639aa6d7ebfbf32b755ddb716dc7bd9ffce6de4f5a55c90cba54a08a4e5d8473427b3ce0fc96c5f8615de6ec05747b80be2e73e97f7af3577452e0ffd09b7961a56d7367cfb9e39d9b8a819d31fdda0ecb3fe1557abeb48ee961b4fa9011a5ed169d65facd07f4b20682d3e9d444edcc35477a00d37b14c0b67b22334ca73beead8ccbb8e8dfa537ed6d0a500679ecf2f82716f94dfabd9f8a3eb009f1d0a5183bad27cd3d744fc6e5d15363be59c786d0ad331a42f7a41e90f1441de8fdfc8d044e648fedc3670a99ced6d8825baf40cd97d9a4e8c07680089420329ce9f874a8c858ce8fd1d765fe113f67f7c59a0fefebc0152c239323245675e95b65bbdc8a049c79112bb66a94939d95e71e2c8f1b77fb2c4f0fcaf6925eed69395c956732c6d86786b86a183f3645564f6d38dd3aac21755bc5a10c92f0f8290540b9ab6601716512755e169600a87ecdc26829fff07f68f77efe060000ffff"
            });
        }

        if (idx == 3) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc983b6ec3300c86855c224386ecb9760ee3c597e8ecbd6b0b4b004b3df88ba644358106c390f5f12d32e1164278bd6e5fdfae2bbcf7736dc7df9bed48abb9d385ce0468a27d2d10714ae8880594dfd2367a783eeede0bc8b6807e0a50c75b7cf35ff424c0e7d0bb7921a56df7648ddff1c95dc1c0c9981edebb641ff3aa2d5f6b477433baf89010b5ee129df68cab0fe8750d04de1994a4d48b0a1db300a68f088075d744a63d18e21d7729e33c2efaabf4aebefd0d3183347a69ec638bfc2efd8cab9c3eb109d1d0f93632da489a6be89a8cf3a3bbc67cb78e4da14b3e9a42d7a41ed8a3893ad0fbe91b099cc81adde7cf142c9da5b105b75e869acfb3a9a003dd9119af97a0a438d1b1775291918c6fa33f1ff71ff653765f24f9f4be0e5cc13c3229428c55377e5be89e0dd4e9705d5ed88a6d31caf1ce4a730fd6eec6dd3eed4f0fa5ee15bdd9d352b81696f11863d70c71cd305e364536bd369d2e396b4eddcee3300b12ebf89965815ceeda59908a244ba2d17e58ea19e4ead72d8c92f08bff430bdbf11b0000ffff"
            });
        }

        if (idx == 4) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc98316ec5300886a35e224386ecef9abe898fd0de2507c9daa11d9010c2e6370f9bb44f1ea288f8030c18def6b16ddbebf5f9f59dba4ab94ab96abdf94dad37adae64065d2ad045a72ec239a1331e707ecb62fc701e7bf602ba3d403f8fbdf53fbdf92b3a29f07fe8c3bcb0d276b8b3e7dcf1ce43c5c0ce985eca65f927bc5acfb7d6313d8c561f32a2b5dda2b3ccbcf980ded640703a939aa89db9e6480f60fa8c02d8764f6486e974c7bd95711917fdbbf4a1bd4301ca208f5d1effc4227f48aff556f4854d88872ec5d8693369eea17b322e8f9e1af3c33ab6846e9dd112ba27f5808c27ea40efe76f2470227b6c5f3e53c874b6c616dc7a056abecc264507b60344a00491e14cc7a74345c6727e8c7e1efb8ff839bb2fd67c795f07ae6019991c21b1aa4bdf2adbe55624e0cc8b58b155a39cecac3cf7607bdcb8db67797a50b6b7f46e4fcbe1aa3c9331c63e33c475c3f8b129b27b6acbe9d6612da9db2a0e659084c74f2900ca5d370b882b9368f2b2b00440f51b16464bf987ff43abf5fe0d0000ffff"
            });
        }

        if (idx == 5) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc983d6ec53008c7517b880c19b2bf317bb69e35a7c9397a8d764042089bbf79f8a37df21045c43fc080e1d10711bd5e5f9fdf53d749f749f7458fbcb9e8e155959c41d70a54d15317e382d01e0f04bf15317938f66df602ba2da01ffb56fa9fdffc159d15f83ff4665e7869dbdc3972ee78e7a66260674c3fe9f6fc935ea5e74beb849e469b0f0551daeed145a6df7c402f6b20389d4e4dccce5273b40730bd47016c7b2432d374bee3decab81917fdbbf4a6bd4d01cea0885d11ffe422bf49bfe831f4814d4884aec5c4693d691ea147326e1e7d6acc37ebd810ba774643e891d4033291a803bd5fbc91c0891cb17df84ca1d3d91b5b70eb95a8f93a9b0c1dd80e108912c4860b1d9f0e1719cff939fab16f3fea17ecbe44f3e17d1db88275644a84e4aa2e7f6b6cd75bb140302f72c5d68c72bab38adc83e571e36e5fe4f9c1d85ed2ab3dad84abf1cc8c3176cd10570de3655364f5d486d3bdc31a52b74d1cea20498f9f5a0094bb6a1630572751e765e10980ead72c8c9ef28bff43bbe8f90d0000ffff"
            });
        }

        if (idx == 6) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc98316ec5300886a35e224386ec6fce257283de3647c82132e6045dda0e480861f39b874dda270f5144fc01060c6ffa98a6e9f5fafefa4c5de7b19dc7765f3bbfb9af9d565532832e15a8a25317e19cd01e0f38bf65317e5897397b01dd1ea0afcb5cfa9fdefc159d14f83ff4665e5869dbdcd973ee78e7a66260674c3f8fcdf24f78959e2fad637a18ad3e644469bb4567997ef301bdac81e0743a35513b73cd911ec0f41e05b0ed9ec80cd3e98e7b2be3322efa77e94d7b9b0294411ebb3cfe89457e937e5fbba20f6c423c7429c64eeb49730fdd937179f4d4986fd6b12174eb8c86d03da907643c51077a3f7f238113d963fbf09942a6b335b6e0d62b50f36536293ab01d200225880c673a3e1d2a3296f363f475997fc4cfd97db1e6c3fb3a7005cbc8e40889555dfa56d92eb72201675ec48aad1ae56467e5b907cbe3c6dd3ecbd383b2bda4577b5a0e57e5998c31f69921ae1ac68f4d91d5531b4eb70e6b48dd56712883243c7e4a0150eeaa59405c99449d97852500aa5fb3305aca3ffc1fda7dedbf010000ffff"
            });
        }

        if (idx == 7) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc98c16dc5300886a32e91430eb9bf3932438e1920bd77b14c920dba497b4042089bdf3c6cd23ef91045c41f60c0f0a68f699a5eafafefcfd4b55fdb7e6de77df09bf33e68552533e852812a3a7511ce09edf180f35b16e3877599b317d0ed01fabacca5ffe9cd5fd14981ff436fe68595b6cd9d3de78e776e2a0676c6f4fdda2cff8457e9f9d23aa687d1ea434694b65b7496e9371fd0cb1a084ea75313b533d71ce9014cef5100dbee89cc309deeb8b7322ee3a27f97deb4b7294019e4b1cbe39f58e437e9e77d28fac026c4439762ecb49e34f7d03d1997474f8df9661d1b42b7ce6808dd937a40c61375a0f7f3371238913db60f9f29643a5b630b6ebd02355f6693a203db01225082c870a6e3d3a12263393f465f97f947fc9cdd176b3ebcaf0357b08c4c8e9058d5a56f95ed722b1270e645acd8aa514e76569e7bb03c6edcedb33c3d28db4b7ab5a7e570559ec918639f19e2aa61fcd814593db5e174ebb086d46d15873248c2e3a71400e5ae9a05c49549d479595802a0fa350ba3a5fcc3ffa19df7f11b0000ffff"
            });
        }

        if (idx == 8) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"cc98316ec5300886a3ee99334451e6be93e41c3945af991b64ef21da0109216c7ef3b049fbe4218a883fc080e14d1fd334bd5e9f5fdfa96b3eaef9b8b6f3e637db79d3aa4a66d0a5025574ea229c13dae301e7b72cc60ffbba642fa0db03f47d5d4affd39bbfa29302ff87decc0b2b6d9b3b7bce1defdc540cec8ce9f37159fe09afd2f3a5754c0fa3d5878c286db7e82cd36f3ea09735109c4ea7266a67ae39d20398dea300b6dd1399613add716f655cc645ff2ebd696f538032c86397c73fb1c86fd2b7f356f4814d88872ec5d8693d69eea17b322e8f9e1af3cd3a36846e9dd110ba27f5808c27ea40efe76f2470227b6c1f3e53c874b6c616dc7a056abecc264507b60344a00491e14cc7a74345c6727e8cbeafcb8ff839bb2fd67c785f07ae6019991c21b1aa4bdf2adbe55624e0cc8b58b155a39cecac3cf76079dcb8db67797a50b697f46a4fcbe1aa3c9331c63e33c455c3f8b129b27a6ac3e9d6610da9db2a0e659084c74f2900ca5d350b882b93a8f3b2b00440f56b16464bf987ff43dbcefb370000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}