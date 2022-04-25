//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface ISecret {
    function submitApplication(string calldata contacts, bytes32 password1, bytes32 password2, bytes32 password3) external;
    function nonce() external view returns(uint24);
}

contract Hack {
    address constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint256 constant PWD1_HASH = 314159265358979323846264338327950288419716939937510582097494459;
    uint256 constant PWD2_HASH = 271828182845904523536028747135266249775724709369995957496696762;
    address constant TARGET_ADDRESS = 0x12689a6B3F9E55E5fEF0Ed8CA77A3f0970799642;
    address constant TARGET_CREATOR = 0xADFfc3D17a537eFCFf6D79f0FC54BF481031eD94;
    uint256 constant TARGET_TIMESTAMP = 1644067340;
    uint256 constant TARGET_GASLIMIT = 30000000;
    uint256 constant TARGET_DIFFICULTY = 340282366920938463463374607431768211454;

    function _nonce() private view returns(uint24) {
        return ISecret(TARGET_ADDRESS).nonce();
    }

    function _getZeroItemFromStack() private view returns(bytes32 packed) {
        bytes memory bias = new bytes(9);
        bytes memory data = abi.encodePacked(bias, _nonce(), FACTORY); // собираем nonce и factory, аналогично нулевой ячейке целевого контракта
        // pwd2 отсусутствует в storage т.к. он immutable и доступен в байт-коде контракта

        assembly {
            packed := mload(add(data, 32)) // упаковываем в 32 байта
        }
    }

    function _getSecret1() private returns(bytes32) {
        uint256 secret = uint256(_getZeroItemFromStack()); // получаем значение, которо должно было быть в нулевом слоте storage
        uint256 n = _nonce(); 
        address f = FACTORY;
        bytes memory data = abi.encodePacked(bytes4(0x22afcccb), uint256(3000));
        bytes memory buffer = new bytes(32);
        assembly {
            let bufref := add(buffer, 0x20) // записываем 32 байта в bufref
            pop( // вычитаем из bufref получшенное в call значение
                call( // 
                    gas(), // лимит газа, в виде достпуного из gasLimit
                    f, // call address
                    0, // value
                    add(data, 0x20),
                    0x24, // размер input
                    bufref, // в bufref будет записан output
                    0x20 //размер output
                )
            ) 
            let y := mload(bufref) // копируем в y bufref
            mstore(bufref, add(add(secret, y), n)) // суммируем в bufref y, secret и сам bufref
            secret := keccak256(bufref, 0x20)  // хеш от bufref + доп.соль
        }
        return bytes32(secret);
    }

    function _getSecret2() private view returns(bytes32) {
        bytes32 pwd1 = _hash(PWD1_HASH, 0);
        return keccak256(abi.encode(pwd1, _nonce()+1)); // + сдвиг nonce
    }

    function _getSecret3() private view returns(bytes32) {
        bytes32 pwd2 = _hash(PWD2_HASH, 1); // учитываем сдвиг nonce при хешировании
        return keccak256(abi.encode(pwd2, _nonce()+2)); // + сдвиг nonce
    }

    function _hash(uint256 value, uint nonce) private pure returns (bytes32) {
        uint256 seed = TARGET_TIMESTAMP + TARGET_GASLIMIT + TARGET_DIFFICULTY + uint256(uint160(TARGET_CREATOR)) + value;
        bytes memory b = new bytes(32);
        uint256 n = nonce + 1;
        assembly {
            seed := mulmod(seed, seed, add(n, 0xffffff))
            let r := 1
            for { let i := 0 } lt(i, 5) { i := add(i, 1) } 
            {
                r := add(r, div(seed, r))
                mstore(add(b, 0x20), r)
                r := keccak256(add(b, 0x20), 0x20)                
            }
            mstore(add(b, 0x20), r)
        }
        return keccak256(b);
    }

    function attack(string memory contact) external {
        ISecret(TARGET_ADDRESS).submitApplication(
            contact,
            _getSecret1(),
            _getSecret2(),
            _getSecret3()
        );
    }
}