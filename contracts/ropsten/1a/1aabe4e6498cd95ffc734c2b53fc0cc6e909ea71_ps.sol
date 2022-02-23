/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5 <0.9.0;

contract ps{
        struct login{ //tabel
        bytes32 username; 
        bytes32 pass;
        }

        login[] public logins;

        function adduser(string memory _user, string memory _pass) external { //memaasukan data yang akan di daftarkan
        logins.push(login(stringToBytes32(_user),stringToBytes32(_pass)));//memaasukan data //stringtobytes32 berfungsi untuk mengkonverd dari bytes menuju string 
         }
        
        function loginuser(string memory _user, string memory _pass) external view returns (bool){ //menampilkan melanjutkan hasil yang di input
        bool ada = false; // false dikarenakan bukan tidak ada melainkan belum di proses
        for(uint256 i=0;i<=logins.length;i++){ //login.length mengikuti data yang di input atau di daftarkan
                
             if(logins[i].username == stringToBytes32(_user)  ){ //user dan pass di samakan dengan data
                if(logins[i].pass == stringToBytes32(_pass)  ){
                    ada = true; //hasil false di awal di rubah menjadi true setelah hasil di temukan
                    break; // ketika hasil di temukan proses berhenti
                    }
            
            }
            }
            return ada; // menampilkan data yang keluar dengan keterangan "ada"
            }

        
        uint256 public hariini; // karna sudah public maka tidak memerlukan bool 
       
        //struct diperuntungkan untuk data yang berbeda dan berubah
        //karna fungsi pengolahan maka harus menggunakan uint256
        

        function jumlahsampahhariini(uint256 _hariini) external {//menggunakan undercore karna 
        
        hariini+=_hariini;

        }

        function stringToBytes32(string memory source) internal pure returns(bytes32 result) {// yang berfungsi untuk mengkonverd di bagian atas
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
        }

        function bytes32ToString(bytes32 _bytes32) internal pure returns(string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}