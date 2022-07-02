/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "./Common/IWhiteList.sol";
//--------------------------------------------
// WHITELIST intterface
//--------------------------------------------
interface IWhiteList {
    //--------------------
    // function
    //--------------------
    function check( address target ) external view returns (bool);
}

//------------------------------------------
// wl_WONDERKIDS_ADD
//------------------------------------------
contract wl_WONDERKIDS_ADD is IWhiteList {
    //---------------------------
    // storage
    //---------------------------
    mapping( address => bool) private _address_map;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor(){
_address_map[0xe26322f69C04754Ba4724EDFBc1D4087A8e64256] = true;
    }

    //--------------------------------------
    // [external] 確認
    //--------------------------------------
    function check( address target ) external view override returns (bool) {
        return( _address_map[target] );
    }

}