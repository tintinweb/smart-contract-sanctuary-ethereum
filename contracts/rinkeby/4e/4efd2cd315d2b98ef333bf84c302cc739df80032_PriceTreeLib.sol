/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

pragma solidity ^0.8.14;
// SPDX-License-Identifier: MIT

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
library TreeLibrary {

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
	    uint count;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(Tree storage self) internal view returns (bool) {
        return self.root == EMPTY;
    }
    function getEmpty() internal pure returns (uint) {
        return EMPTY;
    }
    function getNode(Tree storage self, uint key) internal view returns (Node memory) {
        require(exists(self, key));
        return Node(self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }
    function getCount(Tree storage self) internal view returns (uint) {
        return self.count;
    }

    function insert(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(!exists(self, key));
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);

        self.count++;
    }
    function remove(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(exists(self, key));
        uint probe;
        uint cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];

        self.count--;
    }

    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------
interface Token{
	function balanceOf(address owner) external view returns (uint);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value)external returns (bool);
}

struct OrderTree{
	TreeLibrary.Tree tree;
}

struct PriceTree{
	TreeLibrary.Tree tree;
	mapping(uint => OrderTree) values;
}

library OrderTreeLib{
	using TreeLibrary for TreeLibrary.Tree;
	
	function root(OrderTree storage self) external view returns (uint _key) {
		_key = self.tree.root;
	}
	
	function first(OrderTree storage self) external view returns (uint _key) {
		_key = self.tree.first();
	}
	
	function last(OrderTree storage self) external view returns (uint _key) {
		_key = self.tree.last();
	}
	
	function next(OrderTree storage self, uint key) external view returns (uint _key) {
		_key = self.tree.next(key);
	}
	
	function prev(OrderTree storage self, uint key) external view returns (uint _key) {
		_key = self.tree.prev(key);
	}
	
	function exists(OrderTree storage self, uint key) external view returns (bool _exists) {
		_exists = self.tree.exists(key);
	}
	
	function isEmpty(OrderTree storage self) external view returns (bool) {
		return self.tree.isEmpty();
	}

	function getCount(OrderTree storage self) external view returns (uint) {
		return self.tree.getCount();
	}

	//////////////////////////////////////////

	function insert(OrderTree storage self, uint _key) external {
		self.tree.insert(_key);
	}
	
	function remove(OrderTree storage self, uint _key) external {
		self.tree.remove(_key);
	}

}

library PriceTreeLib{
	using TreeLibrary for TreeLibrary.Tree;

	
	function root(PriceTree storage self) external view returns (uint _key) {
		_key = self.tree.root;
	}
	
	function first(PriceTree storage self) external view returns (uint _key) {
		_key = self.tree.first();
	}
	
	function last(PriceTree storage self) external view returns (uint _key) {
		_key = self.tree.last();
	}
	
	function next(PriceTree storage self, uint key) external view returns (uint _key) {
		_key = self.tree.next(key);
	}
	
	function prev(PriceTree storage self, uint key) external view returns (uint _key) {
		_key = self.tree.prev(key);
	}
	
	function exists(PriceTree storage self, uint key) external view returns (bool _exists) {
		_exists = self.tree.exists(key);
	}
	
	function isEmpty(PriceTree storage self) external view returns (bool) {
		return self.tree.isEmpty();
	}

	function getCount(PriceTree storage self) external view returns (uint) {
		return self.tree.getCount();
	}

	//////////////////////////////////////////

	function getValue(PriceTree storage self, uint _key) external view returns (OrderTree storage) {
		return self.values[_key];
	}

	function insert(PriceTree storage self, uint _key) external {
		self.tree.insert(_key);
	}
	
	function remove(PriceTree storage self, uint _key) external {
		self.tree.remove(_key);
		delete self.values[_key];
	}
}

struct Order{
	address user;
	uint32 pairID;
	uint price;
	uint value;
	bool isSell;
}

struct OrderData{
	address user;
	uint32 pairID;
	uint price;
	uint value;
	bool isSell;
	uint orderID;
}

enum TradeType{
	AddOrder, DelOrder, TradeOrder
}

struct TradeData{
	TradeType tradeType;

	bool isSell;

	address buyUser;
	address sellUser;
	uint32 pairID;
	uint price; 
	uint buyValue;
	uint sellValue;
	uint orderID;
	bool isEndOrder;
}

//因為有Contract code size 24576 bytes限制，所以要分出一部份函數內容到library
library TradeCoinsLib {
	using OrderTreeLib for OrderTree;
	using PriceTreeLib for PriceTree;

	//超過3個indexed變數會出現編譯錯誤
	event Trade(uint time, TradeType tradeType, bool isSell,
			address indexed buyUser, address indexed sellUser, uint32 indexed pairID, uint price,
			uint buyValue, uint sellValue, uint orderID, bool isEndOrder);

	function eventTrade(TradeData memory data) internal {//直接emit的話會遇到stack too deep錯誤
		emit Trade(block.timestamp, data.tradeType, data.isSell, 
			data.buyUser, data.sellUser, data.pairID, data.price, 
			data.buyValue, data.sellValue, data.orderID, data.isEndOrder);
	}

	function eatBuyOrder(uint orderID, uint value, Token t1, Token t2,
			OrderTree storage orderTree, TradeCoins tradeCoins
			) external returns(uint newValue) {

		address tokenAddr1=address(t1);
		address tokenAddr2=address(t2);

		Order memory order=tradeCoins.getOrder(orderID);

		uint chgValue=value*order.price/tradeCoins.cnPriceStd();//優先以訂單的價格為主
		if(chgValue>=order.value){
			if(tokenAddr1==tradeCoins.cnOrgCoin() ){
				payable(msg.sender).transfer(order.value);
			}
			else{
				t1.transfer(msg.sender, order.value);
			}
			tradeCoins.decBalance(tokenAddr1, order.value);

			uint subValue=order.value*tradeCoins.cnPriceStd()/order.price;

			if(tokenAddr2==tradeCoins.cnOrgCoin() ){
				payable(order.user).transfer(subValue);
			}
			else{
				t2.transfer(order.user, subValue);
			}

			value-=subValue;

			eventTrade(TradeData(TradeType.TradeOrder, false, order.user, msg.sender, order.pairID, order.price, 
				order.value, subValue, orderID, true) );
			tradeCoins.setLastPrice(order.pairID, order.price);

			orderTree.remove(orderID);
			tradeCoins.endOrder(orderID, order);
		}
		else{
			uint subValue=chgValue;

			if(tokenAddr1==tradeCoins.cnOrgCoin() ){
				payable(msg.sender).transfer(subValue);
			}
			else{
				t1.transfer(msg.sender, subValue);
			}
			tradeCoins.decBalance(tokenAddr1, subValue);
			order.value-=subValue;
			tradeCoins.decPriceAmount(order.pairID, order.price, subValue);
			
			if(tokenAddr2==tradeCoins.cnOrgCoin() ){
				payable(order.user).transfer(value);
			}
			else{
				t2.transfer(order.user, value);
			}

			bool isEndOrder=(order.value*tradeCoins.cnPriceStd()/order.price==0);
			eventTrade(TradeData(TradeType.TradeOrder, false, order.user, msg.sender, order.pairID, order.price, 
				subValue, value, orderID, isEndOrder) );
			tradeCoins.setLastPrice(order.pairID, order.price);
			value=0;
			
			if(isEndOrder){
				if(order.value>0){//低於最小可交易值，把剩下value還給使用者
					if(tokenAddr1==tradeCoins.cnOrgCoin() ){
						payable(order.user).transfer(order.value);
					}
					else{
						t1.transfer(order.user, order.value);
					}
				}
				
				orderTree.remove(orderID);
				tradeCoins.endOrder(orderID, order);
			}
			else{
				tradeCoins.decOrderValue(orderID, subValue);
			}
		}

		return value;
	}

	function eatSellOrder(uint orderID, uint value, Token t1, Token t2,
			OrderTree storage orderTree, TradeCoins tradeCoins
			) external returns(uint newValue) {

		address tokenAddr1=address(t1);
		address tokenAddr2=address(t2);

		Order memory order=tradeCoins.getOrder(orderID);

		uint chgValue=value*tradeCoins.cnPriceStd()/order.price;//優先以訂單的價格為主
		if(chgValue>=order.value){
			if(tokenAddr2==tradeCoins.cnOrgCoin() ){
				payable(msg.sender).transfer(order.value);
			}
			else{
				t2.transfer(msg.sender, order.value);
			}
			tradeCoins.decBalance(tokenAddr2, order.value);

			uint subValue=order.value*order.price/tradeCoins.cnPriceStd();

			if(tokenAddr1==tradeCoins.cnOrgCoin() ){
				payable(order.user).transfer(subValue);
			}
			else{
				t1.transfer(order.user, subValue);
			}

			value-=subValue;

			eventTrade(TradeData(TradeType.TradeOrder, false, msg.sender, order.user, order.pairID, order.price, 
				subValue, order.value, orderID, true) );
			tradeCoins.setLastPrice(order.pairID, order.price);

			orderTree.remove(orderID);
			tradeCoins.endOrder(orderID, order);
		}
		else{
			uint subValue=chgValue;

			if(tokenAddr2==tradeCoins.cnOrgCoin() ){
				payable(msg.sender).transfer(subValue);
			}
			else{
				t2.transfer(msg.sender, subValue);
			}
			tradeCoins.decBalance(tokenAddr2, subValue);
			order.value-=subValue;
			tradeCoins.decPriceAmount(order.pairID, order.price, subValue);
			
			if(tokenAddr1==tradeCoins.cnOrgCoin() ){
				payable(order.user).transfer(value);
			}
			else{
				t1.transfer(order.user, value);
			}

			bool isEndOrder=(order.value*order.price/tradeCoins.cnPriceStd()==0);
			eventTrade(TradeData(TradeType.TradeOrder, false, msg.sender, order.user, order.pairID, order.price, 
				value, subValue, orderID, isEndOrder) );
			tradeCoins.setLastPrice(order.pairID, order.price);
			value=0;

			
			if(isEndOrder){
				if(order.value>0){//低於最小可交易值，把剩下value還給使用者
					if(tokenAddr2==tradeCoins.cnOrgCoin() ){
						payable(order.user).transfer(order.value);
					}
					else{
						t2.transfer(order.user, order.value);
					}
				}
				
				orderTree.remove(orderID);
				tradeCoins.endOrder(orderID, order);
			}
			else{
				tradeCoins.decOrderValue(orderID, subValue);
			}
		}

		return value;
	}

	
	function getOrders(uint maxCount, PriceTree storage buyPriceTree, PriceTree storage sellPriceTree,
			mapping (uint => Order)	storage orderMap) external view returns 
			(OrderData[] memory buyOrderAr, uint buyCount, OrderData[] memory sellOrderAr, uint sellCount) {

		buyOrderAr=new OrderData[](maxCount);
		sellOrderAr=new OrderData[](maxCount);

		PriceTree storage priceTree;
		OrderTree storage orderTree;
		
		priceTree=buyPriceTree;
		if(!priceTree.isEmpty() ){
			uint findPrice=priceTree.last();
			uint endPrice=priceTree.first();
			
			while(true){
				orderTree=priceTree.getValue(findPrice);

				uint id=orderTree.first();
				uint endID=orderTree.last();
				while(true){
					Order memory order=orderMap[id];
					buyOrderAr[buyCount]=OrderData(order.user, order.pairID, order.price, order.value,
						order.isSell, id);

					buyCount++;
					if(id==endID || buyCount>=maxCount){
						break;
					}
					id=orderTree.next(id);
				}

				if(findPrice==endPrice || buyCount>=maxCount){
					break;
				}
				findPrice=priceTree.prev(findPrice);
			}
		}

		priceTree=sellPriceTree;
		if(!priceTree.isEmpty() ){
			uint findPrice=priceTree.first();
			uint endPrice=priceTree.last();
			while(true){
				orderTree=priceTree.getValue(findPrice);

				uint id=orderTree.first();
				uint endID=orderTree.last();
				while(true){
					Order memory order=orderMap[id];
					sellOrderAr[sellCount]=OrderData(order.user, order.pairID, order.price, order.value,
						order.isSell, id);
					
					sellCount++;
					if(id==endID || sellCount>=maxCount){
						break;
					}
					id=orderTree.next(id);
				}

				if(findPrice==endPrice || sellCount>=maxCount){
					break;
				}
				findPrice=priceTree.next(findPrice);
			}
		}
	}
}

contract TradeCoins {

	address immutable founderAddr;

	struct TokenPair {
		address tokenAddr1;
		address tokenAddr2;
	}
	
	mapping (uint32 => TokenPair) tokenPairMap;
	uint32 tokenPairNum=0;
	
	address immutable public cnOrgCoin;
	
	//////////////////////////////////////////////////

	constructor() {
		founderAddr=msg.sender;
		cnOrgCoin=address(this);//以這個合約的位址當作原生代幣的位址
	}
	
	function setTokenPair(uint32 pairID, address tokenAddr1, address tokenAddr2) public {
		require(msg.sender==founderAddr);
		require(tokenAddr1!=tokenAddr2);
		
		tokenPairMap[pairID]=TokenPair(tokenAddr1, tokenAddr2);
	}
	
	function setTokenPairNum(uint32 num) public {
		require(msg.sender==founderAddr);
		require(num>0 && tokenPairMap[num-1].tokenAddr1!=address(0) && tokenPairMap[num-1].tokenAddr2!=address(0) );
		
		tokenPairNum=num;
	}
	
	function getTokenPair(uint32 pairID) public view returns (address, address) {
		return (tokenPairMap[pairID].tokenAddr1, tokenPairMap[pairID].tokenAddr2);
	}
	
	function getTokenPairs() public view returns (address[] memory, address[] memory) {
		
		address[] memory addrArray1=new address[](tokenPairNum);
		address[] memory addrArray2=new address[](tokenPairNum);

		for(uint32 i=0; i<tokenPairNum; i++){
			addrArray1[i]=tokenPairMap[i].tokenAddr1;
			addrArray2[i]=tokenPairMap[i].tokenAddr2;
		}

		return (addrArray1, addrArray2);
	}
	
	//////////////////////////////////////////////////
	using OrderTreeLib for OrderTree;
	using PriceTreeLib for PriceTree;
	
	mapping (address => uint)		balanceMap;
	mapping (uint32 => PriceTree)	sellTreeMap;
	mapping (uint32 => PriceTree)	buyTreeMap;

	mapping (uint32 => mapping(uint => uint) )	priceAmountMap;
	mapping (uint32 => uint)					lastPriceMap;
	
	mapping (address => OrderTree)	userOrderIDMap;
	mapping (uint => Order)			orderMap;
	
	uint orderNum=0;
	//uint constant public cnPriceStd=10**18;
	uint constant public cnPriceStd=10**2;

	bool isLibCall=false;//為了讓TradeCoinsLib方便存取TradeCoins中的變數
						 //用require(isLibCall)來限制某些external函數只能讓TradeCoinsLib使用

	//需要把library中的event放到contract中才能在ABI中出現
	event Trade(uint time, TradeType tradeType, bool isSell,
			address indexed buyUser, address indexed sellUser, uint32 indexed pairID, uint price,
			uint buyValue, uint sellValue, uint orderID, bool isEndOrder);

	////////////////////////////////////////////////////////////////////////

	function getOrder(uint id) external view returns (Order memory order) {
		return orderMap[id];
	}

	function getLastPrice(uint32 pairID) external view returns (uint lastPrice) {
		return lastPriceMap[pairID];
	}

	function decOrderValue(uint id, uint subValue) external {
		require(isLibCall);

		orderMap[id].value-=subValue;
	}

	function decBalance(address tokenAddr, uint amount) external {
		require(isLibCall);

		balanceMap[tokenAddr]-=amount;
	}

	function setLastPrice(uint32 pairID, uint price) external {
		require(isLibCall);

		lastPriceMap[pairID]=price;
	}

	function endOrder(uint id, Order memory order) external {
		require(isLibCall);
		
		priceAmountMap[order.pairID][order.price]-=order.value;
		userOrderIDMap[order.user].remove(id);
		delete orderMap[id];
	}

	function decPriceAmount(uint32 pairID, uint price, uint subValue) external {
		require(isLibCall);

		priceAmountMap[pairID][price]-=subValue;
	}

	////////////////////////////////////////////////////////////////////////

	function sell(uint32 pairID, uint price, uint value, bool isOrder) public payable {
		require(pairID<tokenPairNum && value>0);

		if(isOrder){
			require(value*price/cnPriceStd>0);
		}

		address tokenAddr1=tokenPairMap[pairID].tokenAddr1;
		address tokenAddr2=tokenPairMap[pairID].tokenAddr2;

		Token t1 = Token(tokenAddr1);
		Token t2 = Token(tokenAddr2);

		if(tokenAddr2==cnOrgCoin){
			require(msg.value>0);

			value=msg.value;//以msg.value為主
		}
		else{
			t2.transferFrom(msg.sender, address(this), value);
		}


		/////////////////////////////////////////////
		//尋找現有匹配的單子
		PriceTree storage priceTree;
		OrderTree storage orderTree;

		priceTree=buyTreeMap[pairID];
		uint findPrice=priceTree.last();
		if(findPrice>0 && findPrice>=price){

			uint endPrice=priceTree.first();
			while(true){
				orderTree=priceTree.getValue(findPrice);

				uint id=orderTree.first();
				uint endID=orderTree.last();
				while(true){
					uint nextID=orderTree.next(id);

					value=eatBuyOrder(id, value, t1, t2, orderTree);

					if(id==endID || value==0){
						break;
					}
					id=nextID;
				}

				if(orderTree.isEmpty() ){
					if(findPrice==endPrice || value==0){
						priceTree.remove(findPrice);
						break;
					}
					else{
						uint savePrice=findPrice;
						findPrice=priceTree.prev(findPrice);
						priceTree.remove(savePrice);

						if(findPrice<price){
							break;
						}
						continue;
					}
				}
				else{
					break;
				}
			}
		}


		if(value==0){
			return;
		}
		if(!isOrder || value*price/cnPriceStd==0){//市價單找不到訂單或是低於最小可交易值，把剩下value還給使用者
			if(tokenAddr2==cnOrgCoin){
				payable(msg.sender).transfer(value);
			}
			else{
				t2.transfer(msg.sender, value);
			}
			return;
		}

		balanceMap[tokenAddr2]+=value;
		
		priceTree=sellTreeMap[pairID];
		if(!priceTree.exists(price) ){
			priceTree.insert(price);
		}
		orderTree=priceTree.getValue(price);

		orderNum++;
		orderTree.insert(orderNum);
		priceAmountMap[pairID][price]+=value;
		
		orderMap[orderNum]=Order(msg.sender, pairID, price, value, true);
		
		userOrderIDMap[msg.sender].insert(orderNum);
		
		TradeCoinsLib.eventTrade(TradeData(TradeType.AddOrder, true,
			address(0), msg.sender, pairID, price,
			0, value, orderNum, false) );
	}

	function eatBuyOrder(uint orderID, uint value, Token t1, Token t2,
			OrderTree storage orderTree) private returns(uint newValue) {

		isLibCall=true;
		value=TradeCoinsLib.eatBuyOrder(orderID, value, t1, t2, orderTree, this);
		isLibCall=false;

		return value;
	}

	//市價單則設price=0
	function buy(uint32 pairID, uint price, uint value, bool isOrder) public payable {
		require(pairID<tokenPairNum && value>0);

		if(isOrder){
			require(price>0 && value*cnPriceStd/price>0);
		}

		address tokenAddr1=tokenPairMap[pairID].tokenAddr1;
		address tokenAddr2=tokenPairMap[pairID].tokenAddr2;

		Token t1 = Token(tokenAddr1);
		Token t2 = Token(tokenAddr2);

		if(tokenAddr1==cnOrgCoin){
			require(msg.value>0);

			value=msg.value;//以msg.value為主
		}
		else{
			t1.transferFrom(msg.sender, address(this), value);
		}

		/////////////////////////////////////////////
		//尋找現有匹配的單子
		PriceTree storage priceTree;
		OrderTree storage orderTree;

		priceTree=sellTreeMap[pairID];
		uint findPrice=priceTree.first();
		if(findPrice>0 && findPrice<=price){

			uint endPrice=priceTree.last();
			while(true){
				orderTree=priceTree.getValue(findPrice);

				uint id=orderTree.first();
				uint endID=orderTree.last();
				while(true){
					uint nextID=orderTree.next(id);

					value=eatSellOrder(id, value, t1, t2, orderTree);

					if(id==endID || value==0){
						break;
					}
					id=nextID;
				}

				if(orderTree.isEmpty() ){
					if(findPrice==endPrice || value==0){
						priceTree.remove(findPrice);
						break;
					}
					else{
						uint savePrice=findPrice;
						findPrice=priceTree.next(findPrice);
						priceTree.remove(savePrice);

						if(findPrice>price){
							break;
						}
						continue;
					}
				}
				else{
					break;
				}
			}
		}

		if(value==0){
			return;
		}
		if(!isOrder || value*cnPriceStd/price==0){//市價單找不到訂單或是低於最小可交易值，把剩下value還給使用者
			if(tokenAddr1==cnOrgCoin){
				payable(msg.sender).transfer(value);
			}
			else{
				t1.transfer(msg.sender, value);
			}
			return;
		}

		balanceMap[tokenAddr1]+=value;
		
		priceTree=buyTreeMap[pairID];

		if(!priceTree.exists(price) ){
			priceTree.insert(price);
		}
		orderTree=priceTree.getValue(price);

		orderNum++;
		orderTree.insert(orderNum);
		priceAmountMap[pairID][price]+=value;
		
		orderMap[orderNum]=Order(msg.sender, pairID, price, value, false);
		
		userOrderIDMap[msg.sender].insert(orderNum);
		
		TradeCoinsLib.eventTrade(TradeData(TradeType.AddOrder, false,
			msg.sender, address(0), pairID, price,
			value, 0, orderNum, false) );
	}

	function eatSellOrder(uint orderID, uint value, Token t1, Token t2,
			OrderTree storage orderTree) private returns(uint newValue) {
		
		isLibCall=true;
		value=TradeCoinsLib.eatSellOrder(orderID, value, t1, t2, orderTree, this);
		isLibCall=false;

		return value;
	}
	
	function delOrder(uint orderID) public {
		require(userOrderIDMap[msg.sender].exists(orderID) );
		
		Order storage order=orderMap[orderID];
		
		address tokenAddr=order.isSell ? tokenPairMap[order.pairID].tokenAddr2 : tokenPairMap[order.pairID].tokenAddr1;

		if(tokenAddr==cnOrgCoin ){
			payable(msg.sender).transfer(order.value);
		}
		else{
			Token t = Token(tokenAddr);
			t.transfer(msg.sender, order.value);
		}
		balanceMap[tokenAddr]-=order.value;
		
		
		PriceTree storage priceTree=(order.isSell ? sellTreeMap[order.pairID] : buyTreeMap[order.pairID]);
		OrderTree storage orderTree=priceTree.getValue(order.price);
		
		orderTree.remove(orderID);
		priceAmountMap[order.pairID][order.price]-=order.value;

		if(orderTree.isEmpty() ){
			priceTree.remove(order.price);
		}

		userOrderIDMap[msg.sender].remove(orderID);
		
		emit Trade(block.timestamp, TradeType.DelOrder, order.isSell,
			order.isSell ? address(0) : msg.sender, order.isSell ? msg.sender : address(0), 
			order.pairID, order.price,
			order.isSell ? 0 : order.value, order.isSell ? order.value : 0, 
			orderID, true);
	}

	function getUserOrder(address addr) public view returns (OrderData[] memory ) {
		OrderTree storage orderTree=userOrderIDMap[addr];

		uint count=orderTree.getCount();

		OrderData[] memory orderArray=new OrderData[](count);
		
		if(count==0){
			return orderArray;
		}
		
		uint id=orderTree.first();
		uint lastID=orderTree.last();
		uint i=0;
		while(true){
			Order memory order=orderMap[id];
			orderArray[i]=OrderData(order.user, order.pairID, order.price, order.value,
				order.isSell, id);
		
			if(id==lastID){
				break;
			}
			id=orderTree.next(id);
			i++;
		}

		return orderArray;
	}
	
	function getOrders(uint32 pairID, uint maxCount) public view returns (
			OrderData[] memory buyOrderAr, uint buyCount, OrderData[] memory sellOrderAr, uint sellCount) {
		require(pairID<tokenPairNum && maxCount>0);

		(buyOrderAr, buyCount, sellOrderAr, sellCount)=TradeCoinsLib.getOrders(maxCount,
			buyTreeMap[pairID], sellTreeMap[pairID] , orderMap);
	}

	function getState(uint32 pairID, uint maxCount) public view returns (uint _lastPrice,
			uint[] memory buyPriceAr, uint[] memory buyAmountAr, uint buyCount,
			uint[] memory sellPriceAr, uint[] memory sellAmountAr, uint sellCount) {

		require(pairID<tokenPairNum && maxCount>0);

		_lastPrice=lastPriceMap[pairID];

		buyPriceAr=new uint[](maxCount);
		buyAmountAr=new uint[](maxCount);
		sellPriceAr=new uint[](maxCount);
		sellAmountAr=new uint[](maxCount);

		PriceTree storage priceTree;
		
		priceTree=buyTreeMap[pairID];
		
		if(!priceTree.isEmpty() ){
			uint findPrice=priceTree.last();
			uint endPrice=priceTree.first();

			while(true){
				buyPriceAr[buyCount]=findPrice;
				buyAmountAr[buyCount]=priceAmountMap[pairID][findPrice];

				buyCount++;
				if(findPrice==endPrice || buyCount>=maxCount){
					break;
				}
				findPrice=priceTree.prev(findPrice);
			}
		}

		priceTree=sellTreeMap[pairID];
		if(!priceTree.isEmpty() ){
			uint findPrice=priceTree.first();
			uint endPrice=priceTree.last();

			while(true){
				sellPriceAr[sellCount]=findPrice;
				sellAmountAr[sellCount]=priceAmountMap[pairID][findPrice];

				sellCount++;
				if(findPrice==endPrice || sellCount>=maxCount){
					break;
				}
				findPrice=priceTree.next(findPrice);
			}
		}
	}

	//////////////////////////////////////////////////

	function getBalance() public view returns (uint) {
		return address(this).balance;
	}

	function getOtherBalance() public view returns (uint) {
		return address(this).balance-balanceMap[cnOrgCoin];
	}

	function withdrawOther(uint value) public{
		require(msg.sender==founderAddr);
		require(value<=getOtherBalance() );
		
		payable(msg.sender).transfer(value);
	}

	function getTokenBalance(address tokenAddr) public view returns (uint) {
		return balanceMap[tokenAddr];
	}

	function getTokenOtherBalance(address tokenAddr) public view returns (uint) {		
		Token t = Token(tokenAddr);
		uint total=t.balanceOf(address(this) );

		return total-balanceMap[tokenAddr];
	}

	function withdrawTokenOther(address tokenAddr, uint value) public{
		require(msg.sender==founderAddr);
		require(value<=getTokenOtherBalance(tokenAddr) );
		
		Token t = Token(tokenAddr);
		t.transfer(msg.sender, value);
	}
}