/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL 3.0

pragma solidity ^0.8.12;

contract IfElse {
    function gender(uint types) public pure returns (string memory) {
        if (types < 10) {
            return "female";
        } else if (types < 20) {
            return "male";
        } else {
            return "transgender";
        }
    }

    function numbers(uint random) public pure returns (uint) {
        if (random < 20) {
            return 40000;
        } else if (random < 40) {
            return 700000;
        } else if (random == 65) {
            return 55000;
        } else {
            return 20000;
        }
    }

    function age(uint classification) public pure returns (string memory) {
        if (classification < 3) {
            return "baby";
        } else if (classification < 12) {
            return "child";
        } else if (classification < 17) {
            return "teenager";
        } else if (classification == 18) {
            return "old enough to drink";
        } else if (classification < 30) {
            return "young adult";
        } else if (classification < 70) {
            return "adult";
        } else {
            return "elderly";
        }
    }

    function country(string memory nationality) public pure returns (string memory) {
        if (keccak256(bytes(nationality)) == keccak256(bytes("nigerian"))) {
            return 'You are from Nigeria';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("german"))) {
            return 'You are from Germany';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("british"))) {
            return 'You are from England';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("american"))) {
            return 'You are from United States';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("chinese"))) {
            return 'You are from China';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("finnish"))) {
            return 'You are from Finland';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("australian"))) {
            return 'You are from Australia';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("canadian"))) {
            return 'You are from Canada';
        } else if (keccak256(bytes(nationality)) == keccak256(bytes("brazilian"))) {
            return 'You are from Brazil';
        } else {
            return 'You are from a country I would like to visit';
        }
    }

    function test(uint xy) public pure returns (uint) {
        if (xy > 50) {
            return 1;
        }
        return 2;
    }

    function testabc(uint xyz) public pure returns (string memory) {
        if (xyz > 50) {
            return 'male';
        }
        return 'female';
    }
}