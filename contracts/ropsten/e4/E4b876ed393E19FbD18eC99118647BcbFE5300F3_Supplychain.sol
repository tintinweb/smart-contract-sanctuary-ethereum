/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.0;

contract Supplychain{

    address owner;
   
   constructor() public {
      owner = msg.sender;
   }

uint256 product_id=0;
uint256 worker_id=0;

struct Product{
    uint256 id;
    string name;
    string price;
    string description;
    string reqtemp;
    string manufacturing;
    uint256 timestamp;
}

struct Status{
    string location;
    uint256 timestamp;
    string temp;
    string humidity;
    string heatindex;
    uint256 w_id;
    uint256 p_id;
    uint256 total_quantity;
    bool flag;
}

struct Worker{
    string name;
    uint256 id;
    uint256 timestamp;
}

struct Data {
    uint256 temp;
    uint256 humidity;
    uint256 hindex;
    uint256 pid;
}

modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

Product[] public products_list;
Product private productInfo;
Status[] public productStatus;
Status private statusInfo;
Worker[] public workers_list;
Worker private workerInfo;
Data[] public Data_list;
Data private DataInfo;


mapping(uint256 => Status[]) public product_Status;
mapping (uint256 => Product) public products;
mapping (uint256 => Worker) public workers;
mapping (uint256 => Data[]) public data;


function setWorker(string memory name) public  payable
{
    workerInfo=Worker(name,worker_id,block.timestamp);
    workers[worker_id]=workerInfo;
    workers_list.push(workerInfo);
    worker_id++;

}

function AddProduct(
    string memory name,
    string memory price,
    string memory description,
    string memory reqtemp,
    string memory manufacturing) public payable
{
    productInfo=Product(product_id,name,price,description,reqtemp,manufacturing,block.timestamp);
    products[product_id]=(productInfo);
    products_list.push(productInfo);
    product_id++;

}

function AddStatus( string memory location,
    
    string  memory temp,
    string  memory humidity,
    string  memory heatindex,
    uint256 wid,
    uint256 pid,
    uint256 total_quantity,
    bool flag
) public payable {

    statusInfo= Status(location,block.timestamp,temp,humidity,heatindex,wid,pid,total_quantity,flag);
    product_Status[pid].push(statusInfo);
    productStatus.push(statusInfo);
}


function AddData( uint256 temp,
    uint256 humidity,
    uint256 hindex,uint256 pid) public payable {

        DataInfo = Data(temp,humidity,hindex,pid);
        data[pid].push(DataInfo);
        Data_list.push(DataInfo);
        }
function getWorkerssList() public view returns(Worker[] memory)
{
    return workers_list;
}

function getProductStatus(uint256 id) public view returns(Status[] memory){

    return product_Status[id];
}

function getProductData(uint256 id) public view returns(Data[] memory){

    return data[id];
}

function getProducts() public view returns(Product[] memory){

    return products_list ;
}


}