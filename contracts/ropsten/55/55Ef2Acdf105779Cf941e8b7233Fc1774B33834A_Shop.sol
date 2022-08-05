// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Shop {
    address payable public owner;
    uint public T_invest = 0;
    uint public ROI = 0;
    uint public T_days = 0;
    uint public T_earns = 0;

    uint256[] public levelIncome = [80, 12, 5, 3];
    enum Level {
        ClassA,
        ClassB,
        ClassC
    }

    MEMBERS[] public memberArray;
    SPACES[] public sp_Array;
    MY_PRODUCTS[] public prod_Array;
    FIN_BANK[] public finBank_Array;
    mapping(address => MEMBERS) public members;
    mapping(address => SPACES) public spaces;
    mapping(address => MY_PRODUCTS) public my_products;
    mapping(address => FIN_BANK) public fin_bank;
    struct MEMBERS {
        string userCode;
        address account;
        address ref;
        uint created_at;
    }

    struct SPACES {
        address account;
        uint ClassValue;
        Level UserLevel;
    }

    struct MY_PRODUCTS {
        address account;
        string prodID;
        string prodName;
        uint ClassValue;
    }

    struct FIN_BANK {
        address account;
        uint T_invest;
        uint ROI;
        uint T_days;
        uint T_earns;
        uint P_startingTime;
        uint dayStartTime;
        bool status;
        uint256 withdrawn;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // add
    function addMember(string memory _code, address _ref) public {
        MEMBERS memory newUp = MEMBERS(
            _code,
            msg.sender,
            _ref,
            block.timestamp
        );
        members[msg.sender] = newUp;
        memberArray.push(newUp);
        createFINBANK();
    }

    function createFINBANK() private {
        FIN_BANK memory newfinb = FIN_BANK(
            msg.sender,
            T_invest,
            ROI,
            T_days,
            T_earns,
            0,
            0,
            true,
            0
        );
        fin_bank[msg.sender] = newfinb;
        finBank_Array.push(newfinb);
    }

    function buyProduct(
        uint _amount,
        string memory _prodID,
        string memory _prodName
    ) public payable {
        require(
            msg.value >= (_amount * (1 ether)),
            " Please pay the required amount!"
        );
        MEMBERS storage data = members[msg.sender];
        require(
            msg.sender == data.account,
            " Invalid User Account Please Make registration first"
        );
        //    return  (data.unLevel1,data.unLevel2,data.unLevel3);
        if (payable(owner).send((msg.value * levelIncome[0]) / 100)) {
            // payable(data.unLevel1).transfer((msg.value * levelIncome[1]) / 100);
            // payable(data.unLevel2).transfer((msg.value * levelIncome[2]) / 100);
            // payable(data.unLevel3).transfer((msg.value * levelIncome[3]) / 100);

            MEMBERS storage l1 = members[data.ref];
            if (payable(l1.ref).send((msg.value * levelIncome[1]) / 100)) {
                MEMBERS storage l2 = members[l1.ref];
                if (payable(l2.ref).send((msg.value * levelIncome[2]) / 100)) {
                    MEMBERS storage l3 = members[l2.ref];
                    payable(l3.ref).transfer(
                        (msg.value * levelIncome[3]) / 100
                    );
                }
            }
        }

        MY_PRODUCTS memory newPod = MY_PRODUCTS(
            msg.sender,
            _prodID,
            _prodName,
            _amount
        );
        my_products[msg.sender] = newPod;
        prod_Array.push(newPod);

        SPACES storage sp = spaces[msg.sender];
        uint256 N_roi;
        if (sp.UserLevel == Level.ClassA) {
            N_roi = 1;
        }
        if (sp.UserLevel == Level.ClassB) {
            N_roi = 2;
        }
        if (sp.UserLevel == Level.ClassC) {
            N_roi = 3;
        }

        FIN_BANK storage updateFB = fin_bank[msg.sender];
        updateFB.T_invest += _amount;
        updateFB.ROI = N_roi;
        updateFB.dayStartTime = block.timestamp;
        if (updateFB.P_startingTime == 0) {
            updateFB.P_startingTime = block.timestamp;
        }
    }

    // function update_FIN_BANK(address _)

    function buySpaces(uint _amount) public payable {
        require(
            msg.value >= (_amount * (1 ether)),
            " Please pay the required amount!"
        );
        MEMBERS memory data = members[msg.sender];
        require(
            msg.sender == data.account,
            " Invalid User Account Please Make registration first"
        );

        Level lev;
        if (_amount >= 5 && _amount <= 20) {
            lev = Level.ClassA;
        }
        if (_amount >= 250 && _amount <= 1000) {
            lev = Level.ClassB;
        }
        if (_amount >= 2500 && _amount <= 10000) {
            lev = Level.ClassC;
        }

        SPACES memory new_sp = SPACES(msg.sender, msg.value, lev);
        spaces[msg.sender] = new_sp;
        sp_Array.push(new_sp);
    }

    // get INcome

    function getDailyIncone() public {
        FIN_BANK storage upd____daily_income = fin_bank[msg.sender];
        require(
            upd____daily_income.P_startingTime + (86400 * 30) >=
                block.timestamp,
            " Your ROI is already Expired Please Upgrade your Account!"
        );

        // require(upd____daily_income.status == true, "something goes wrong");
        if (upd____daily_income.status == true) {
            uint myRoi = (upd____daily_income.T_invest *
                upd____daily_income.ROI) / 100;
            if (block.timestamp >= upd____daily_income.dayStartTime + 86400) {
                upd____daily_income.T_earns += myRoi;
                upd____daily_income.status = false;
                upd____daily_income.T_days += 1;
                upd____daily_income.dayStartTime = block.timestamp;
                upd____daily_income.status = false;
                upd____daily_income.T_earns += myRoi;
            }
        }
        if (
            !upd____daily_income.status &&
            block.timestamp >= upd____daily_income.dayStartTime + 86400
        ) {
            upd____daily_income.status = true;
        }

        // set timing sasa
    }

    function withdraw(uint _amount) public payable {
        FIN_BANK storage _pesa = fin_bank[msg.sender];
        require(_pesa.T_earns >= _amount, " insufficient funds");

        if (payable(msg.sender).send(msg.value)) {
            _pesa.T_earns -= _amount;
            _pesa.withdrawn += _amount;
        }
    }
}

// function withdraw() external {
//  5        uint256 amount = balanceOf[msg.sender];
//  6        balanceOf[msg.sender] = 0;
//  7        (bool success, ) = msg.sender.call.value(amount)("");
//  8        require(success, "Transfer failed.");
//  9    }

// https://dapp-world.com/smartbook/return-on-investment-and-smart-contracts-part-1-qFBq

//  npx hardhat run scripts/deployShop.js --network ropsten
// npx hardhat verify --network ropsten