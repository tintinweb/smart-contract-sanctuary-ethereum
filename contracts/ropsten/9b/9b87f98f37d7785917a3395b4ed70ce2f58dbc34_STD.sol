/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.7.0;

    contract STD {
        address owner;
        // 宣告 string 變數設定為組員學號。
        string info = "410721307";
        // 記錄學號
        event record(string);
        /* 防止Replay attacks */
        mapping(uint256 => bool) usedNonces;
        /* 發布合約時, 將owner 設為發佈地址 */
        constructor() public {
            owner = msg.sender;
        }
        /* memory : 執行時變數分配在記憶體, 非永久儲存 */
        /* nonce 防止 replay attacks */
        function verify(bytes32 _message, uint8 nonce, bytes memory signture) public{
            require(!usedNonces[nonce]);
            usedNonces[nonce] = true;
    
            /* 驗證的前綴 */
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            /* 將prefix 與 _message 使用abi.encodepacked(．,．)重新編碼，並使用 keccak256(．)做雜湊運算 */
            _message = keccak256(abi.encodePacked(prefix,_message));
            /* 呼叫recoverSigner(．, ．)函數，返回執行簽章的地址 = owner, 使用require(．)*/
            require(recoverSigner(_message, signture) == owner);
            /* 紀錄事件 */
            emit record(info);
        }
        /* selfstruct 銷毀合約的函數 */
        function kill() public {
            require(msg.sender == owner);
            selfdestruct(msg.sender);
        }
        /* signature 是由 v, r , s 組成 */
        function splitSignature(bytes memory sig) internal pure returns(uint8 v, bytes32 r, bytes32 s){
            require(sig.length == 65);
            assembly {
                r := mload(add(sig, 32))
                /* mload(．) 從第32 個位置開始讀取32 個位元組 */
                s := mload(add(sig, 64))
                v := byte(0, mload(add(sig, 96)))
            }
            return (v, r, s);
        }
        function recoverSigner(bytes32 _message, bytes memory sig) internal pure returns (address)
        {
            (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
            /* 使用ecrecover(．,．,．,．)返回簽章地址，ecrecover(hash, v ,r ,s); */

            return ecrecover(_message, v, r, s);
        }
    }