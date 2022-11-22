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

import {IBucketStorage, Compressed} from "solidify-contracts/IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract TraitBucketStorage0 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 7;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 260;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"0a13703e0c2508";

        uint256[] memory num = new uint[](7);
        for (uint256 i; i < 7;) {
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
                uncompressedSize: 100,
                data: hex"621061906050625063d066d0673065b066f0608872ca294d75cfc92c49ce50084a4d712f4aac742f4a4dcd0bc8cccb0e282d2ac8498d4ccdc9c92f77ce2fcecd4c568008b9e6e564a66794a4e6a5a64045bc12535215c01a01010000ffff"
            });
        }

        if (idx == 1) {
            return Compressed({
                uncompressedSize: 113,
                data: hex"625063d062d06330623063b062b0677061f064f0630886c208865886248674861c9ffcbc74741c9c915f548295c84dccc9c14900020000ffff"
            });
        }

        if (idx == 2) {
            return Compressed({
                uncompressedSize: 2167,
                data: hex"74934f68d44c18c63b93cc4cbecf9b1411155c841e548a07115abdb5ca5651ac69b1d45b76f3ba1b9b4d6a36b1aee742c1a322782a05bd089e44911e043d889782a0a83715143d58bd8807ad0799d9cc9f90ecedfdbd4fc2f3e499c9d0c7a1ef43bf1145dbd15e74108da3e3e81c0ad0325a45ebe80dda447ff136bc1b1fc047f1497c01b7f155bc826fe1bbf8017e865fe20f78136f593bad316bce5ab26e5b0fad0debab8dec3df6987dd6be642fdb6bf663fb85fdd6fe62ff22840c931172984c92799290ebe40e79425e914fe427b5e9301da147689d9ea72d9ad21b7495dea38fe853ba41dfd1cff407fdc3fe633bd83e76881d63536c963558875d632bec265b63f7d93a7bce5eb3f7ec1bdb72fe777639fb9d7167ca99775a138977056aa3b589d06b2e68c840cd49bc1449a8275e4fcf004a980e22f5f674962c86ea7d177c39ceb5831426e36e2768d6466ba7a10591ef25bd9ad02bf69309749b10a515d289ce22247152a1d4332ff1032faa90a693f82274bb95afcd782d907eb28e02670599976230efa58000a6ccdb315114642c5cf00d1235e51f28a3989899220fa291e73009c010790a834408cd2ef81afa11a23068b55388c02f1fd720517ec7203df71824cbd31ba4ab231cf4003fc77a18a4cd763973c55ec6ad90f2a4158a0c5921a97c159a8816873e44d511ca928c5056b44f59133e7944797f0a9c15647e830ce657a88000a6cc2f9189e216190b177c83c43d3ae5f9503e8cd256f65012f2164a7be953125439258557a354d94d7191151fe0ed980b5e4f91010a0ff0820a2c1a32372ef8268a8edcb811f37fff0ca45ee8668d5e6d66014248e3e2d14ec411f06f90d1d59ca9350f9ccf3cab1a01e49a2794a30897830b7e3e89484600619b7ac982f25590694138e720acd5ccbd7310e672eebbe7c4edf351f8cf7a8d464f1a6ac8b4c00d2570433d0328811baa59184a72c19763df30f1a2cb59102a4f93b3822c9c350b7313b9bf6611c1c07e0abde04134892cff020000ffff"
            });
        }

        if (idx == 3) {
            return Compressed({
                uncompressedSize: 466,
                data: hex"62a8616861e864e86398cc3083612ec32286e50c6b1836326c63d8c6b097e138c34586db0c4f19de33fc646466e46514679446810a8c2a50a8c1a8c368c068c268c168c3e8c0e8c2e8c1e8c318cc18c598c898c198cf58c658cbd8c2d8cd38897116e322c6558c9b1877311e623ce598925f94989493ea98975e544912e19299989b9f97e292599c9c5a949799974e6d965b6651aa476a6251896f7e7e9e7f412a51382831332f29bf3c283527b12235855c2a3833255537b532955c1a100000ffff"
            });
        }

        if (idx == 4) {
            return Compressed({
                uncompressedSize: 160,
                data: hex"44cc3d0ac2401047f1ff312c83a590464f60fc88085a18493fae63b23ac9849d35a0e021acbdac8504bb57fc7818618c09a658638f1257f478e18dcf6c99e442666cf3de53d46099af9223bb3a1372b734f8a6e1f360560fee28ba3aa7278bb06d482e69a3da2645c72e9213b6ad9e6cf03b6dd5091fd4385da868f8af8a7b5bfdaaf4a6e11b0000ffff"
            });
        }

        if (idx == 5) {
            return Compressed({
                uncompressedSize: 420,
                data: hex"348fb18e13410c86ed969e8e62bae378014ac4264a561c271db948a17566acc4da597bf1ceb20ac5359488868a8257e005e86828a878011a4a0a4a6ab45951d9d6afcfffffc333d84182065e41813b78071fe0137c862ff015bec177f8013fe117fc863ff01701efe17d7c808ff0313ec12b7c8984191deff02dbec78f4f5f0b15f38b3e2ca8ab28362379ea434da5224da45431a970656335c486cba42ca82b243a338ba35b2bbcb0716fa7b3eadc47d612b694a56f4997a451f41056995a5e0ab5a66939381d56e2bcca36b2afccb92f61437a605f3b495e3bb75d16ad295bcd94f6a4699addd194fb9add66fb2b722a1ca6b0cf45a365bdb6238d4d78b87666bdfc7fdd883697d7663a45bc9109ba38d77c31309fabb88dba21d1986d489b61bf670fcb2136b7cd90f3e9b6a3c8a1e6dc72d90a396d454f33b493128ff3b39dbc214ff3fe2f0000ffff"
            });
        }

        if (idx == 6) {
            return Compressed({
                uncompressedSize: 106,
                data: hex"6210609065d06530677066f06408618877cacf4d4a2d52f04a4cce4e2d71c94ccccdcf4b51f04b4dcece494c4e75cfcf495170ce48ccccf3482dca572f560829cdcb4cf6c8cf4fc94c85900a2ef9e5795ea989795013024af3b2a14c40000000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}