/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract TugasProject {
        // Alert saat memo baru dibuat.
        event NewMemo(
            address indexed from,
            uint256 timestamp,
            string name,
            string message
        );

        // Struk memo setelah dibuat.
        struct Memo {
            address from;
            uint256 timestamp;
            string name;
            string message;
        }

        // Daftar memo yang diterima
        Memo[] memos;

        // Address milik pembuat contract
        address payable owner;
        
        // Logika pembuat memo
        constructor() {
            owner = payable(msg.sender);
        }
        
        /**
        * @dev Fungsi membelikan kopi untuk pembuat contract
        * @param _name Nama yang membelikan kopi
        * @param _message Pesan yang dikirimkan oleh pembeli kopi
        */
        function buyCoffe(string memory _name, string memory _message) public payable {
            require(msg.value > 0, "tidak bisa membeli kopi dengan 0 eth");

            // Menambah memo ke penyimpanan
            memos.push(Memo(
                msg.sender,
                block.timestamp,
                _name,
                _message
            ));

            // Lakukan alert saat memo baru dibuat
            emit NewMemo(
                msg.sender,
                block.timestamp,
                _name,
                _message
            );
        }

        /**
        * @dev Fungsi untuk mengirimkan semua saldo yang tersimpan di contract kepada pemilik contract
        */
        function withdrawTips() public {
            require(owner.send(address(this).balance));
        }

        /**
        * @dev Fungsi untuk mengambil semua memo yang diterima dan tersimpan di blockchain
        */
        function getMemos() public view returns(Memo[] memory) {
            return memos;
        }
    }