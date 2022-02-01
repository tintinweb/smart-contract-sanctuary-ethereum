/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

contract Management {
    
    receive() external payable {}

    function distribute() external payable {
        uint256 balance = msg.value / 10000; // This is 0.01% of the total balance -> Needed to do presition calculations without floating point.
        
        require(payable(0x81cc8A4bb62fF93f62EC94e3AA40A3A862c54368).send(balance * 5000));
        require(payable(0x10f3667970FAd7dA441261c80727caCd8B164806).send(balance * 900));
        require(payable(0x7A6c41c001d6Fbf4AE6022E936B24d0d39AE3a25).send(balance * 310));
        require(payable(0x848CF28ddDfa170b6754fa95E9A20A6821379E43).send(balance * 310));
        require(payable(0xcc2ba3C4E74A531635b928D2aC5B3f176C8B6ec3).send(balance * 205));
        require(payable(0x37B8C37EB031312c5DaaA02fD5baD9Dc380a8cc4).send(balance * 105));
        require(payable(0xC970bd4E2dF5F33ea62c72b9c3d808b8a609e5e1).send(balance * 530));
        require(payable(0xED7AdfDBbcB1b5C93fa8B6b28B0Fc833Fa68BCA0).send(balance * 560));
        require(payable(0x50a583Ab2432BF3bC5E7458C8ed10BC5Ec3AB23E).send(balance * 560));
        require(payable(0x3b0f95D44f629e8E24a294799c4A1D21f06B6969).send(balance * 210));
        require(payable(0x02916D0f68a02c502476DC630628B01Ee36A7826).send(balance * 35));
        require(payable(0x41b6cb632F5707bF80a1c904316b19fcBee2a4cF).send(balance * 35));
        require(payable(0x2C1Ba2909A0dC98A6219079FBe9A4ab23517D47E).send(balance * 35));
        require(payable(0x58EE6F81AE4Ed77E8Dc50344Ab7571EA7A75a9b7).send(balance * 15));
        require(payable(0x38cA9DAACB4d5e493132c2fE9507bbaee4AB86aC).send(balance * 45));
        require(payable(0x07b699C2B00c08cb017e93e45fab21EA3D5c6Bdc).send(balance * 45));
        require(payable(0xC3Bd2c6E850d97c3C76CDE990Ba5B362E983842A).send(balance * 100));

        require(payable(0x7CEAD16936c2fCd51Bb54c3A9e8D1780ea434991).send(address(this).balance));
    }

    function royaltyDistribute() external {
        uint256 balance = address(this).balance / 10000;

        require(payable(0xC970bd4E2dF5F33ea62c72b9c3d808b8a609e5e1).send(balance * 1200));
        require(payable(0x7A6c41c001d6Fbf4AE6022E936B24d0d39AE3a25).send(balance * 2000));
        require(payable(0x848CF28ddDfa170b6754fa95E9A20A6821379E43).send(balance * 2000));
        require(payable(0x81cc8A4bb62fF93f62EC94e3AA40A3A862c54368).send(balance * 1000));
        require(payable(0xcc2ba3C4E74A531635b928D2aC5B3f176C8B6ec3).send(balance * 1500));
        require(payable(0x1b2766bF472D863cc6A2ff05393EDecC4c62AAa1).send(balance * 700));
        require(payable(0x5787A9c0687AEd39286c1D135839660Bb90EA1B4).send(balance * 600));

        require(payable(0x7CEAD16936c2fCd51Bb54c3A9e8D1780ea434991).send(address(this).balance));
    }


}