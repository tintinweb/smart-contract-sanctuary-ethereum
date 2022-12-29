/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/passaddresslist.sol

pragma solidity ^0.8.0;

contract passaddresslist is Ownable {
    mapping (uint256 => address) public mintList;
    uint256 public totalAdressQuantity;
    uint256 private mintMaxAmount = 100;

    constructor() {
        mintList[0] = 0xF464009100b1D1540e85f3fAA18FbE38EA4CEBfF;
        mintList[1] = 0xc2546aA56004feF0CFcd81ACcab2fc9999257f03;
        mintList[2] = 0x03f66A25d5746E13a64295F7B57622155F9Af9F8;
        mintList[3] = 0x972CCba923b9970504057dD185c70036A0d70824;
        mintList[4] = 0x624AC37dC2627454024B00F12D2538D6B837eEf6;
        mintList[5] = 0xBf5a19e9cd0e7DfD193962deD8896cdF729Aec56;
        mintList[6] = 0x80E75ed9062779560831C7808067bc0c673B17A5;
        mintList[7] = 0xA8f16210aB92Cec5c74A74f62516Ba25a62D3054;
        mintList[8] = 0x816978C6CC3EEde8823aed2B1D2db904505beA4b;
        mintList[9] = 0x039e01717916faFd3151d366Beda49989095D066;
        mintList[10] = 0xFB784F18ec0387bABA727Ef1DF6a470FCC02e6A7;
        mintList[11] = 0x5AD264fE5aE7912b5A9d0d424e17EFCd85F19768;
        mintList[12] = 0x292470C6aC59444FeD0aAABEAbe1A98CF71BdE82;
        mintList[13] = 0x017D46B2B01f7e9Aa7C4C2dB97E67F29d40838b6;
        mintList[14] = 0x7Ec1B412Ce73254b2a965F1251837f52e30B9217;
        mintList[15] = 0x4c9BCb7F4370625a88160f1c1f8b10945E3d8320;
        mintList[16] = 0x44FaA42Da632DEcbdC7D40231Eb115DE6CB60f06;
        mintList[17] = 0xB3B63a345768e1E43951DF7eBfBA4cC464270671;
        mintList[18] = 0x68a7E6c301f936C22F9446f5B562126a9b3aA9F3;
        mintList[19] = 0xB69Cb3704882d087EA2f0b085eDb62f95e6c7e82;
        mintList[20] = 0xf49D0A9B7fF310A66460fF562AF2E2c9FCb555C0;
        mintList[21] = 0x64541D14fC2ba37bFfCd209b5173479D41d1513D;
        mintList[22] = 0x9BE0BB49F27aDfd42512163e8EE1dd88e8f10ED9;
        mintList[23] = 0x5e93303aEadccf996bd77EB91A9FaB241880334f;
        mintList[24] = 0x36946563C5a488dDc4feaBA434dF74A957e5DdD9;
        mintList[25] = 0xFdb2E7640375f0ef8CB2b3E6Cf9469Aa457831d5;
        mintList[26] = 0xcDA447E6FaA574D75B07E18aEc62E31F44Ea6c5e;
        mintList[27] = 0x85D5bD42AB8200F3d4914d7920AA36e73D7e3B8A;
        mintList[28] = 0x448BC8B5f99C45D6433698C8a11D589aE28Af73D;
        mintList[29] = 0x18d2a9bf6a6feBD5da6F8Efe15769B8d4Ec3beb9;
        mintList[30] = 0x1Fb2DF535d1c7969a2964F49E25cE3a05bf45A91;
        mintList[31] = 0x945475aF27f187506A896ccdD2CbAe103d6490AA;
        mintList[32] = 0x068C3aBA4F6d2c91179d43edA8Ee5F6A72E1e710;
        mintList[33] = 0xBd7c22c48659f5E46109778114a9186E5D22E54c;
        mintList[34] = 0xddF21318ca81F9dcB3f143b40B95C72328c46892;
        mintList[35] = 0xdBE00211F2E86F47523778Fa4F00e30a00634c54;
        mintList[36] = 0x32c44006B19C13B5FED744F90649aFC57715a419;
        mintList[37] = 0x344F79c03B71fa1711f7661FA4A7d308e78e1841;
        mintList[38] = 0xcB3f514B38dc2153aC8b3863a83318e35966F346;
        mintList[39] = 0xA1B54d98eE00619cCd725DE2a10183ED1c20b461;
        mintList[40] = 0x9fD5f6Ac3E7F278D727d4cD20BBDcAa6321027eb;
        mintList[41] = 0x90138735d4a44FB2Dec46e9e7bFE18569854033b;
        mintList[42] = 0xEaF3daA857f4f4C579A19027A2CEedC81179101E;
        mintList[43] = 0xaDfD630D3d36D6fD95B37112FE80F58f4Ec7755e;
        mintList[44] = 0xf4E54339403CF8201B55AA97b3B3baD8221B239C;
        mintList[45] = 0x802a201e40C8510Ee41057A99fdB8abb3E1b444a;
        mintList[46] = 0xBe2581584137FB9e53bF8D6c75e33bF938e709a1;
        mintList[47] = 0x80242Af0Ba90B21046709CD0d1Da396bBce4f232;
        mintList[48] = 0x6b7AabD0D382bc4f65998938fa5244979Fceed47;
        mintList[49] = 0x71e0D859c2F318f76712E352120A367Ae4dAfE60;
        mintList[50] = 0x98700566C4DE1EA5b107EEaFd95C243292022885;
        mintList[51] = 0xd1961eCb2373Ab47Ef2a13062744E1b889cec31e;
        mintList[52] = 0x1dE51791a8476A26675555478B102b12Ab2B67A4;
        mintList[53] = 0xd4c4dd385b97CD1d4823458BC69B579fC89a59F9;
        mintList[54] = 0xaC1152605D6A066a78E1bD693304190087d6C4A5;
        mintList[55] = 0x4f515b745e16D7eaC1029633E30097C83Ff90d71;
        mintList[56] = 0x43D62E93dc0aF8DF2dCEC7e6566056b2734C77a7;
        mintList[57] = 0xDAD662787B2398AD69e98519AeDfD0D848a0F821;
        mintList[58] = 0xCFcb18A76DAF95633ca762C5E46DdB5E04ADE31F;
        mintList[59] = 0x35b63a6ccA6563fd3495d51F45aebeCF0E1616cF;
        mintList[60] = 0xc8331Db1414bdF20a88f0192351d3eCFaD11aAC1;
        mintList[61] = 0x4D655208ab35fD7146311656806174E72863f7Be;
        mintList[62] = 0xa9B2D28D4eEeBb29C6b07B34A21E5496A4767511;
        mintList[63] = 0x5c651A2aaEb0e64A7a5da535023dE744E02d5a28;
        mintList[64] = 0x824Cd75db050A171bbfDB8067544BB009a866B87;
        mintList[65] = 0xB6B99F923E22e1AE463AC6009E4DA81E1e5B58c2;
        mintList[66] = 0x28Dd1372349695DcBCbAe903Ee76dBb9DD7c6b9e;
        mintList[67] = 0xf2332D727a23A8dB6c2B8DE1Bf66C93f0472e35d;
        mintList[68] = 0x8Cd64dC3d242D0Ddb1603485bAac67B621EFEe6a;
        mintList[69] = 0x870BA521b5830Ce144DD0e824DA837269491C8FA;
        mintList[70] = 0x99cdb33Df8726F1952af7f60a02e70436241d499;
        mintList[71] = 0x1fBb0324177bcDa7B0F0c6ab4808a23d9120708a;
        mintList[72] = 0x8722FBBAB0Cd663D82248DC80AcDD6aCfE26f70d;
        mintList[73] = 0xBE849cE1A292A47fb14a8a60119FE85fde2aBD62;
        mintList[74] = 0x274A0e3301110d6A2059Bf258a38b4df8357AFec;
        mintList[75] = 0x848e4DAfDFa495d05F5Bea829EC715D7C095C682;
        mintList[76] = 0x34c2B83f0Fe192afF0F00588556e56b09D4B5f26;
        mintList[77] = 0x65f5F7086D5F5658C0E3e81C53a1B01F1BCcB3eC;
        mintList[78] = 0xb85925F8C9c0a890B03EDeDCB237a54e6549a0B1;
        mintList[79] = 0x47eC6B2B692FDE71172ABeA77Df8097aa950f3e3;
        mintList[80] = 0xa0751827DA7a5cE235D85694164382Ee8920648D;
        mintList[81] = 0xA3e21743A8B9BcD815f5F71fC83705D54b0DaBB6;
        mintList[82] = 0x29233799279A15cdd5E0bad1D02585d182C8044F;
        mintList[83] = 0xD250acC86F704F1e226ba39Cca9aB31D2d5e9714;
        mintList[84] = 0xfdE8b81E98D03A1861E43769CF96cAFe825a3Ce8;
        mintList[85] = 0x2099296f14173b27bbe49F9232d3eF95dfD1a259;
        mintList[86] = 0x5D18b05A850F040b35C7318223143F52f7e1d363;
        mintList[87] = 0xedB08e8719c2BeEaF94a12E9C1EdE25064655087;
        mintList[88] = 0x93192edf07d482331564DF31A70DA3Cb020bEaF6;
        mintList[89] = 0xc2B7014AA9BFEA7f9442dF001a6CcC59646a52Dd;
        mintList[90] = 0x85ab567d13086cd03976765a2c9a49e8E1DA9187;
        mintList[91] = 0xBA4AF3Ddaa1644504A3f4E2A6CB73D8958803467;
        mintList[92] = 0x2B48178c649980F1235942a44634EBeA4E37b005;
        mintList[93] = 0x96Dc081e52240545a339f748e2d09fe57Ea417ae;
        totalAdressQuantity = 94;
    }

    function addAdress(address to) public onlyOwner{
        require(totalAdressQuantity < mintMaxAmount);
        mintList[totalAdressQuantity] = to;
        totalAdressQuantity ++;
    }

    function getAddress(uint256 key) public view returns (address) {
        return mintList[key];
    }

    function getQuantity() public view returns(uint256) {
        return totalAdressQuantity;
    }
}