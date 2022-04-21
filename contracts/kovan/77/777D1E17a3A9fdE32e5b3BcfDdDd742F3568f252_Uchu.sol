/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// contract Uchu is Initializable {
contract Uchu {
    event Log(address from, string operation, uint16 name, uint256 value);
    address payable public owner;

    /**
    * asset:ETH = 10, WETH = 11, USDT = 20, USDC = 21, WBTC = 30
    * the frontend need decode the number to string name for display.
    * product_id start from 1.
    */
    struct Product {
        uint8 product_id;
        uint8 asset;
        string product_name;
        uint balance;
        uint debt;
        uint lending_share;
        uint borrowing_share;
        uint lastest_change_time;
        address creator;
    }

    // position_id start from 1.
    struct Position {
        uint position_id;
        uint share;
    }

    struct Loan {
        uint32 loan_id;
        uint share;
    }

    uint8 private proCount;
    uint private loanCount;
    uint private positionCount;
    Product[] private product_list;
    mapping (address => mapping(uint8 => Loan)) private loan_map;
    mapping (address => mapping(uint8 => Position)) private position_map;

    // function initialize() public payable initializer {
    //     owner = payable(msg.sender);
    // }

    function createProduct(uint8 asset, string memory name) public returns (bool) {
        for(uint8 i=0; i<proCount; i++) {
            if (asset == product_list[i].asset)
                return false;
        }
        product_list.push(Product(++proCount, asset, name, 0, 0, 0, 0, block.timestamp, msg.sender));
        return true;
    }

    function getProducts() public view returns (Product[] memory) {
        return product_list;
    }

    function getProduct(uint8 productId) public view returns (Product memory) {
        for (uint8 i=0; i<proCount; i++) {
            if (product_list[i].product_id == productId) {
                return product_list[i];
            }
        }
    }

    /**
    * start: the start millisecond
    * end : the end millisecond
    * return: natural days
    **/
    function getDays(uint start, uint end) private pure returns (uint) {
        if (start > end) {
            return 0;
        }
        return end / 1 days - start / 1 days;
    }

    function getPositions(address user) public view returns (Position[] memory) {
        Position[] memory pos = new Position[](positionCount);
        for(uint8 i=0; i<positionCount;) {
            pos[i]= position_map[user][++i];
        }
        return pos;
    }

    function getPosition(address user, uint8 productId) public view returns (Position memory) {
        return position_map[user][productId];
    }

    function getLoans(address user) public view returns (Loan[] memory) {
        Loan[] memory loan = new Loan[](loanCount);
        for(uint8 i=0; i<loanCount; i++) {
            loan[i]= loan_map[user][i];
        }
        return loan;
    }

    /**
    * deposit by current product, product_id = index
    **/
    function deposit(address user, uint8 productId) public payable returns (bool) {
        if (proCount > 0) {
            Product memory product = getProduct(productId);
            product.lastest_change_time = block.timestamp;
            setProductBalance(product, msg.value);
            position_map[user][productId] = lenderShare(user, productId, msg.value);
            return true;
        } else {
            require(proCount > 0, "No product!");
            return false;
        }
    }

    function withdraw(address user, uint8 productId, uint amount) public returns (bool) {
        if(product_list[productId].balance >= amount) {
            payable(user).transfer(amount);
            return true;
        } else {
            require(product_list[productId].balance >= amount, "Allowance is not enough!");
            return false;
        }
    }

    function setProductBalance(Product memory product, uint amount) private {
        if (product.debt == 0) {
            product.lending_share = amount;
            product.balance = amount;
        } else {

        }
    }

    function setProductDebt(Product memory product) private returns (uint) {

    }

    function setProductLendShare(Product memory product, int amount) private returns (uint) {

    }

    function setProductBorrowShare(Product memory product) private returns (uint) {

    }

    /**
    * return a position to update it.
    **/
    function lenderShare(address user, uint8 productId, uint amount) private returns (Position memory) {
        Product memory product = getProduct(productId);
        Position memory pos = position_map[user][productId];
        if (pos.position_id == 0) {
                return Position(++positionCount, amount);
        } else {
            if (product.debt == 0) {
                pos.share += amount;
            } else {
                pos.share += amount;
            }
            return pos;
        }
    }

    function productPrice() private pure returns (uint) {
        
    }

    function lenderBalance(Product memory product) private returns (uint) {

    }

    function borrowerShare(Product memory product) private returns (Loan memory) {

    }

    function borrowerDebt(Product memory product) private returns (uint) {

    }
    
    function borrow(address user, uint amount, uint8 productId) public returns (bool) {
        if (product_list[productId].debt >= amount) {
            Product memory product = getProduct(productId);
            product.lastest_change_time = block.timestamp;
            loan_map[user][productId] = borrowerShare(product);
            payable(user).transfer(amount);
            return true;
        } else {
            require(product_list[productId].debt >= amount, "Allowance is not enough!");
            return false;
        }
    }

    function repay(address user, uint8 productId) public payable returns (bool) {
            return true;
    }

}