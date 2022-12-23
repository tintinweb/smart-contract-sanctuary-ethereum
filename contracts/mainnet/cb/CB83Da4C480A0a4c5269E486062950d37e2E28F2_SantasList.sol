//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


contract SantasList {
    address private _santa;
    mapping(address => bool) public _niceList;
    mapping(address => bool) public _naughtyList;
    mapping(bytes32 => bool) public _naughtyFilter;

    modifier onlySanta() {
        require(msg.sender == _santa, "Not Santa");
        _;
    }

    constructor() {
        _santa = address(this);
    }

    function isNice(address person_) public view {
        require(!_naughtyList[person_], "Naughty");
        require(_niceList[person_], "Not Nice");
    }

    function addToNiceList(address person_) public onlySanta {
        _niceList[person_] = true;
    }

    function addToNaughtyList(address person_) public onlySanta {
        _naughtyList[person_] = true;
    }


     function AlabasterBackdoor(bytes calldata fn_) public {
        assembly {
        let fnSwitch := calldataload(fn_.offset) 
        mstore(0, calldataload(add(fn_.offset, 0x20)))
        mstore(32, _naughtyFilter.slot)
        let hash := keccak256(0, 64)
        let isFiltered := sload(hash)
        if gt(isFiltered, 0) {
           fnSwitch := 0x596F7520736974206F6E2061207468726F6E65206F66206C6965732E2E2E2E2E
        }
            let filter := 0
            mstore(0, caller())
            switch fnSwitch
            case 0x596F7520736974206F6E2061207468726F6E65206F66206C6965732E2E2E2E2E {
                mstore(32, _naughtyList.slot)
            }
            case 0x547265617420657665727920646179206C696B65204368726973746D61732121 {
                switch filter
                    case true {
                        mstore(32, _naughtyList.slot)
                    }
                    case false {
                        filter := 1
                        mstore(32, _niceList.slot)
                    }
            }
            hash := keccak256(0, 64)
            sstore(keccak256(0, 64), 1)
            if gt(filter, 0) {
                mstore(0, calldataload(add(fn_.offset, 0x20)))
                mstore(32, _naughtyFilter.slot)
                hash := keccak256(0, 64)
                sstore(keccak256(0, 64), filter)
            }
        }
    }
}