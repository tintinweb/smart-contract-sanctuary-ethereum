/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

pragma solidity ^0.8.12;

// SPDX-License-Identifier: GPL-3.0-or-later

contract AxSECRETxBEACHxSoLUTioNSzzz {

/* 1AxSECRETxBEACHxSoLUTioNSzzzRf6MZh monitored on bitcoin.sv (bsv) */
/* Copyright Secret Beach Solutions 2022 */
/* John Rigler [email protected] */

address public owner;

constructor() {
    owner = msg.sender;
   }

function one_anchor(

    string memory url,
    string memory title,
    address payable anchor1
 
) public
    {
    // Use this well-known unspendable address as a common anchor
    payable(0x1111111111111111111111111111111111111111).transfer(1);
    payable(anchor1).transfer(2);
    }

function two_anchors(

    string memory url,
    string memory title,
    address payable anchor1,
    address payable anchor2
 
) public
    {
    // Use this well-known unspendable address as a common anchor
    payable(0x1111111111111111111111111111111111111111).transfer(1);
    payable(anchor1).transfer(2);
    payable(anchor2).transfer(3);
    }

function three_anchors(

    string memory url,
    string memory title,
    address payable anchor1,
    address payable anchor2,
    address payable anchor3
 
) public
    {
    // Use this well-known unspendable address as a common anchor
    payable(0x1111111111111111111111111111111111111111).transfer(1);
    payable(anchor1).transfer(2);
    payable(anchor2).transfer(3);
    payable(anchor3).transfer(4);
    }

function cashout ( uint256 amount ) public
    {
    address payable Payment = payable(owner);
       if(msg.sender == owner)
            Payment.transfer(amount);

    }
    fallback () external payable {}
    receive () external payable {}
}
/*
// The following PHP script creates the unspendable addresses
// I haven't added a Checksum function, but at this 
// point I prefer to show something simpler
// Checksum can be added with javascript
// 
// The point of including this is to show that you could start
// with this contract and then extract a known web service
// so that your homepage simple becomes a page on your personal
// computer if you run apache and php. By coding into the contract's
// comment field, we can extend its functionality to remove the
// need for a centralized server node.

<html>
<table border=1><form>
<tr><td><label for="from">From:           </label><td><input type="radio" name="first" id="from" value="1Ax">
<tr><td><label for="to">To:               </label><td><input type="radio" name="first" id="to" value="1Bx">
<tr><td><label for="about">About:         </label><td><input type="radio" name="first" id="about" value="1Cx">
<tr><td><label for="location">Location:   </label><td><input type="radio" name="first" id="about" value="1Lx">
<tr><td><label for="rest">Topic/Subject:  </label><td><input type="text"  name="rest">
<tr><td><td><input type="submit">

</form></table>
<br>
<hr>
<br>

<?php

// This was constructed quickly as an example, grab the exact python script from IPFS 
// I pinned it in pinata.io and on two other IPFS nodes
// Please pin a copy yourself if you can
// This can be run locally on your own machine
//
// Example, to add a geographical location, use What3Words:
// https://what3words.com/clip.apples.leap
// 1LxCLiPvAPPLESvLEAFzzzzzzzzzYq9iaa
// LxCLiPvAPPLESvLEAFzzzzzzzzz
// Ethereum=0x18b10545bc9be88e5704608c7fe8050f641901ff


function unspendable($first,$rest="")
{
        return `python3 /opt/alp/QmSrMiD6n2x3zyHGHXpJhLiHZBcWcAHRZHRbh7MwBF2EcU $first "$rest"`;
}

$word=unspendable($_REQUEST[first],$_REQUEST[rest]);

echo $word;
echo "<br>";
$ethereum=substr($word,1,27);
echo "<br> $ethereum";
echo "<br>";
echo "Ethereum=0x" . `echo $ethereum | base58 -d | xxd -p -c 80`;

?>
</html>
*/