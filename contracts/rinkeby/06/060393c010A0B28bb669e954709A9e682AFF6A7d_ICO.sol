// SPDX-License-Identifier: MIT

//При написании я не брал никаких готовых решений для ICO (за исключением openzeppelin ERC20), всю логику написал с нуля с высоты своего скромного опыта.


pragma solidity ^0.8.4;


import "./IERC20.sol";


contract ICO {



    address owner;
    address [] public whiteList;
    uint public saleStart;
    uint public tokensOneEther;
    uint public tokens;
    uint public userBalance;
    address tokenAddress = 0xda7Ae2f90aa9D88307312B91AD683202B698dd75;

    constructor () {
        owner = msg.sender;
        saleStart = block.timestamp;
    } 


    //Здесь хранится информация о балансах адресов
    mapping (address => uint) public balances;

    //Здесь хранится информация о вайтлисте
    function addToWhiteList (address _address) public {
        require (msg.sender == owner, "You are not an owner!");
        whiteList.push(_address);
    }

    receive () external payable {
        require (msg.value > 0, "Empty transact");
        require (saleStart + 48 days > block.timestamp, "ICO is over"); 
        require (msg.value / 1000000000000000000 % 1 == 0, "Fractional numbers are not allowed");

        if (saleStart + 3 days > block.timestamp) {
            addToBalance(msg.sender, msg.value, 1);
            }
        //Здесь подразумевается что месяц равен 31 дню
        else if (saleStart + 34 days > block.timestamp) {
            addToBalance(msg.sender, msg.value, 2);
            }

        else if (saleStart + 48 days > block.timestamp ) {
            addToBalance(msg.sender, msg.value, 3);
            }
        
    }



    function addToBalance (address _address, uint _amount, uint8 _stage) internal {
        // Расчитываем сколько зачислить TTT на баланс покупателю
        // Смотрим стадию ICO
        if (_stage == 1){
            tokensOneEther = 42;
        }
        else if (_stage == 2){
            tokensOneEther = 21;
        }
        else if (_stage == 3){
            tokensOneEther = 8;
        }

        //Вычисляем кол-во токенов
        tokens = tokensOneEther * _amount / 1000000000000000000;

        //Если баланс покупателя 0, то добавляем токены. Если не 0, то складываем старый баланс + новый. 
        //Это на случай, если покупатель инвестирует два и более раз

        if (balances[_address] == 0) {
            balances[_address] = tokens;
        }
        else {
            userBalance = balances[_address];
            balances[_address] = userBalance + tokens;
        }
        
    }         

    
 
    function payOut(uint _amount) public {

        //До окончания ICO могут вывести только те кто в вайтлисте.
        require (balances[msg.sender] >= _amount, "Please check your address or balance");

        if (saleStart + 48 days < block.timestamp) {
            userBalance = balances[msg.sender];
            balances[msg.sender] = userBalance - _amount;
            IERC20(tokenAddress).transfer(msg.sender, _amount * 1000000000000000000);
        }

        else if (saleStart + 48 days > block.timestamp) {
            for (uint i; i < whiteList.length; i++) {
                if (whiteList[i] == msg.sender) {
                    userBalance = balances[msg.sender];
                    balances[msg.sender] = userBalance - _amount;
                    IERC20(tokenAddress).transfer(msg.sender, _amount * 1000000000000000000);
                }
                else {
                    revert ("You are not in White List");
                
                }
            }
        }
    }

}