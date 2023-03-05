pragma solidity ^0.6.0;

import "./IExerciceSolution.sol";

interface INephte 
{
    function mintage(address addresse) external returns (uint256);
}

contract minter is IExerciceSolution
{   

    address myaddress = 0x793d2996FA121F40Be379dc0204f8C91520B0884;
    address myERC721 = 0x176D29AF1271D5d3C27faAF8Fdd77590A9f07aC5;

    INephte nepht = INephte(myERC721);



    function ERC721Address() external override returns (address)
    {
        return myERC721;
    }

	function mintATokenForMe() external override returns (uint256)
    {
        return nepht.mintage(msg.sender);        
    }

	function mintATokenForMeWithASignature(bytes calldata _signature) external override returns (uint256)
    {
        return (56);
    }

	function getAddressFromSignature(bytes32 _hash, bytes calldata _signature) external override returns (address)
    {
        return (myaddress);
    }

	function signerIsWhitelisted(bytes32 _hash, bytes calldata _signature) external override returns (bool)
    {
        return (false);
    }

	function whitelist(address _signer) external override returns (bool)
    {
        return (false);
    }
}

pragma solidity ^0.6.0;


interface IExerciceSolution
{
	function ERC721Address() external returns (address);

	function mintATokenForMe() external returns (uint256);

	function mintATokenForMeWithASignature(bytes calldata _signature) external returns (uint256);

	function getAddressFromSignature(bytes32 _hash, bytes calldata _signature) external returns (address);

	function signerIsWhitelisted(bytes32 _hash, bytes calldata _signature) external returns (bool);

	function whitelist(address _signer) external returns (bool);
 
}