// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./interfaces/IUSDC.sol";

contract SeniorPool {
    IUSDC public USDc;

    address seniorPoolAddress;
    mapping(address => uint256) public addressToAmountLended;
    uint256 public totalLended;

    constructor(address _seniorPoolAddress) {
        seniorPoolAddress = _seniorPoolAddress;
        USDc = IUSDC(0xeb8f08a975Ab53E34D8a0330E0D34de942C95926);
    }

    struct investor {
        uint256[] investments;
        uint256 totalInvestment;
    }

    address[] investors;

    mapping(address => investor) public addressToInvestor;

    function checkInvestor(address walletAddress) public view returns (bool) {
        bool success = false;
        for (uint256 i = 0; i < investors.length; i++) {
            if (investors[i] == walletAddress) {
                success = true;
                break;
            }
        }
        return success;
    }

    function fund(uint256 $USDC) public {
        // payable(seniorPoolAddress).transfer(msg.value);
        USDc.transferFrom(msg.sender, seniorPoolAddress, $USDC * 10**6);
        investor storage Investor = addressToInvestor[msg.sender];
        // Investor.investments.push(msg.value);
        if (checkInvestor(msg.sender) == false) {
            investors.push(msg.sender);
        }
        Investor.totalInvestment += $USDC;
    }

    function getSeniorPoolAddress() public view returns (address) {
        return seniorPoolAddress;
    }

    function getSeniorPoolBalance() public view returns (uint256) {
        return USDc.balanceOf(seniorPoolAddress);
    }

    // function investmentsPerAddress(address investorAddress)public view returns( uint256  [] memory){
    //  investor storage Investor = addressToInvestor[investorAddress];
    //  return Investor.investments;
    // }

    modifier onlyAdmin() {
        require(msg.sender == seniorPoolAddress);
        _;
    }

    modifier onlyInvestor() {
        require(checkInvestor(msg.sender));
        _;
    }

    function getInvestorsAddress() public view returns (address[] memory) {
        return investors;
    }

    function withdraw() external payable onlyAdmin {
        payable(seniorPoolAddress).transfer(address(this).balance);
    }

    function withdrawUser(uint256 withdrawAmount) public payable onlyInvestor {
        investor storage Investor = addressToInvestor[msg.sender];
        require(Investor.totalInvestment >= withdrawAmount);
        payable(msg.sender).transfer(withdrawAmount);
    }

    function seniorPoolBalance() public view returns (uint256) {
        return seniorPoolAddress.balance;
    }

    function lend(address projectAddress) public payable onlyAdmin {
        payable(projectAddress).transfer(msg.value);
        addressToAmountLended[projectAddress] += msg.value;
        totalLended += msg.value;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

interface IUSDC {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     * @return Return the amount held by address
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @return Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * @return Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}