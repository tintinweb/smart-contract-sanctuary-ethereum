// SPDX-License-Identifier: GPL-3.0

/**
 * @Author VRON
*/

pragma solidity >=0.7.0 <0.9.0;
import "./SafeMath.sol";

interface BUSD {
    function balanceOf(address _address) external returns (uint256);

    function transfer(address _address, uint256 value) external returns (bool);

    function transferFrom(
        address _sender,
        address recipient,
        uint256 value
    ) external returns (bool);
}

interface Context{
    function onlyOwner(address _address) external view;
    function onlyAdmin(address _address) external view;
}

contract Donation{
    using SafeMath for uint256;
    Context context;
    BUSD BUSD_token;
    mapping(string=>address) private foundationAddress;  // stores a foundation address and name
    mapping(address=>uint256) private foundationID;  // stores the array index of each stored foundation addr

    uint256 private totalDonation; // total amount donated
    address[] private foundationList;  // list of all foundations address
    uint256 distributionTime;

    constructor(address BUSD_address, address context_address){
        context = Context(address(context_address));
        BUSD_token = BUSD(address(BUSD_address));
        distributionTime = block.timestamp + 4 weeks;
    }

    // function returns BUSD token address
    function getBUSDAddress() external view returns (address){
        return address(BUSD_token);
    }

    // function returns Context address
    function getContextAddress() external view returns (address){
        return address(context);
    }

    /**
     * @dev function returns a list of supported foundations
    */
    function getFoundationAddresses() external view returns (address[] memory){
        return foundationList;
    }

    /**
     * @dev function gets the address of a particular foundation
    */
    function getFoundationAddr(string memory foundationName) external view returns (address){
        return foundationAddress[foundationName];
    }

    // function updates BUSD token address
    function updateBUSDTokenAddress(address _address) external{
        context.onlyOwner(msg.sender);
        BUSD_token = BUSD(address(_address));
    }

    // function updates Context contract address
    function updateContextAddress(address _address) external{
        context.onlyOwner(msg.sender);
        context = Context(address(_address));
    }

    // external function for _addFoundationAddress(string, address)
    function addFoundationAddress(string memory foundationName, address _address) external{
        _addFoundationAddress(foundationName, _address);
    }

    // external function for _updateFoundationAddress(string, address)
    function updateFoundationAddress(string memory foundationName, address _address) external{
        _updateFoundationAddress(foundationName, _address);
    }

    // external function for removeFoundation(string)
    function removeFoundation(string memory foundationName) external{
        _removeFoundation(foundationName);
    }

    // external function calls the donate(uint256) function
    function donate(uint256 _amount) external{
        _donate(_amount, msg.sender);
    }

    // function returns total donation made
    function getTotalDonation() external view returns (uint256){
        return totalDonation;
    }

    /**
    * @dev function is used to add a new
    * gambling foundation address
    */
    function _addFoundationAddress(string memory foundationName, address _address) private {
        context.onlyOwner(msg.sender);
        require(foundationAddress[foundationName] == address(0), "Foundation listed");
        foundationAddress[foundationName] = _address;  // add foundation to storage
        foundationList.push(_address);  // push foundn addr to array
        foundationID[_address] = foundationList.length - 1;  // add foundn addr ID to storage
    }

    /**
     * @dev function updates the address of a particular foundation
    */
    function _updateFoundationAddress(string memory foundationName, address _address) private{
        context.onlyOwner(msg.sender);
        require(foundationAddress[foundationName] != address(0), "Foundation not found");
        _removeFoundation(foundationName);
        _addFoundationAddress(foundationName, _address);
    }

    /**
     * @dev function removes a particular foundation address from the list
     * of listed foundation addresses
    */
    function _removeFoundation(string memory foundationName) internal{
        context.onlyOwner(msg.sender);
        require(foundationAddress[foundationName] != address(0), "Foundation not found");
        foundationList[foundationID[foundationAddress[foundationName]]] = foundationList[foundationList.length - 1];
        foundationList.pop();
        delete foundationID[foundationAddress[foundationName]];
        delete foundationAddress[foundationName];
    }

    /**
     * @dev function is used in making donation to gambling foundations
    */
    function _donate(uint256 _amount, address _sender) private {
        require(_amount != 0, "Amount can't be zero");
        require(BUSD_token.balanceOf(_sender) >= _amount, "Insufficient balance.");
        BUSD_token.transferFrom(_sender, address(this), _amount);
        totalDonation = totalDonation.add(_amount);
        _distributeDonation();
    }

    function _distributeDonation() private {
        uint256 contract_balance = BUSD_token.balanceOf(address(this));
        // check if a distributionTime <= currentTime
        if(distributionTime <= block.timestamp){
            // check if there are foundation addresses listed.
            if(foundationList.length > 0){
                // divide distribution amongst listed addresses
                uint256 distributionAmount = contract_balance / foundationList.length;
                // iterate through addrs and distribute funds
                for(uint i=0; i<foundationList.length; i++){
                    BUSD_token.transfer(foundationList[i], distributionAmount);
                }
                // reset time
                distributionTime = block.timestamp + 4 weeks;
            } else {
                // distribution time elapsed but no addr to send funds to - reset dis time
                distributionTime = block.timestamp + 4 weeks;
            }
        }
    }

}