pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract GRInsurance is Ownable {

    IERC20 private grom;

    constructor(
        IERC20 gromContract
    ) {
        grom = gromContract;
    }

    struct Insurance {
        uint id;
        string currencyName;
        uint oneCoinPrice;
        string buyEndDateAt;
        string endDateAt;
    }

    Insurance[] public insurances;

    struct InsuranceUser {
        uint id;
    }

    mapping(address => InsuranceUser[]) public insuranceUsers;

    function addInsurance(uint _id, string memory _currencyName, uint _oneCoinPrice, string memory _buyEndDateAt, string memory _endDateAt) external onlyOwner {
        Insurance memory new_insurance = Insurance(_id, _currencyName, _oneCoinPrice, _buyEndDateAt, _endDateAt);
        insurances.push(new_insurance);
    }

    function getInsuranceById(uint _id) public view returns (uint id, string memory currencyName, uint oneCoinPrice, string memory buyEndDateAt, string memory endDateAt) {
        for (uint i = 0; i <= insurances.length; i++) {
            Insurance storage insurance = insurances[i];
            if (_id == insurance.id) {
                return (insurance.id, insurance.currencyName, insurance.oneCoinPrice, insurance.buyEndDateAt, insurance.endDateAt);
            }
        }
        return (0, "Empty", 0, "", "");
    }

    function addInsuranceUser(uint _id) private {
        InsuranceUser memory new_insurance = InsuranceUser(_id);
        insuranceUsers[msg.sender].push(new_insurance);
    }

    function getInsuranceUserByAddress(address _address) external view returns (InsuranceUser[] memory) {
        return insuranceUsers[_address];
    }

    function buyByGr(uint256 _amount, uint256 _id) public {
        uint256 allowance = grom.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");

        (bool sent) = grom.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to send GROM");

        addInsuranceUser(_id);
    }

    function withdrawGr() external onlyOwner {
        uint256 balance = grom.balanceOf(address(this));
        require(balance > 0, "Amount sent is not correct");

        grom.transfer(owner(), balance);
    }
}