/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface P_A {
	function getToEffieOnSaleIds() external view returns(uint[] memory);
	function getToKyrinOnSaleIds() external view returns(uint[] memory);
	function getToEffieSaledIds() external view returns(uint[] memory);
	function getToKyrinSaledIds() external view returns(uint[] memory);
	function getToEffieCanceledIds() external view returns(uint[] memory);
    function getToKyrinCanceledIds() external view returns(uint[] memory);
	function getSaleById(uint saleId) external view returns(string memory);

	function getToEffieIds() external view returns(uint[] memory);
	function getToKyrinIds() external view returns(uint[] memory);
	function getToEffieDoneIds() external view returns(uint[] memory);
	function getToKyrinDoneIds() external view returns(uint[] memory);
	function getAwardById(uint awardId) external view returns(string memory);

	function addOnSale(string memory name, uint cnt, uint value, bool longTerm, address sender) external;
	function deleteOnSale(uint saleId, address sender) external;
	function cancelOnSale(uint saleId, address sender) external;
	function changeOnSaleLongTerm(uint saleId, address sender) external;
	function buyOnSale(uint saleId, address sender) external;
	function addAward(string memory name, uint cnt, address sender) external;
	function finishAward(uint awardId, address sender) external;
	function changeAwardCnt(uint awardId, uint cnt, address sender) external;
}

interface P_T {
	function getToEffieIds() external view returns(uint[] memory);
	function getToKyrinIds() external view returns(uint[] memory);
	function getToEffieFinishedIds() external view returns(uint[] memory);
	function getToKyrinFinishedIds() external view returns(uint[] memory);
	function getToEffieVerifiedIds() external view returns(uint[] memory);
	function getToKyrinVerifiedIds() external view returns(uint[] memory);
	function getToEffieCanceledIds() external view returns(uint[] memory);
    function getToKyrinCanceledIds() external view returns(uint[] memory);
	function getTaskById(uint taskId) external view returns(string memory);

	function addTask(string memory name, uint value, bool longTerm, address sender) external;
	function deleteTask(uint taskId, address sender) external;
	function cancelTask(uint taskId, address sender) external;
	function changeTaskLongTerm(uint taskId, address sender) external;
	function finishTask(uint taskId, address sender) external;
	function verifyTask(uint taskId, bool fail, address sender) external;

	function checkin(address sender) external;
}

interface P_M {
	function getCurrentTime() external view returns(string memory);
	function getMemIds() external view returns(uint[] memory);
	function getMemoryById(uint memId) external view returns(string memory);
	function getSumDaysByMemId(uint memId) external view returns(uint);
	function getWaitDaysByMemId(uint memId) external view returns(uint);
	function getDateByMemIdAndSumDays(uint memId, uint sumDays) external view returns(string memory);

	function addMemory(uint year, uint month, uint day, string memory name) external;
	function modifyMemoryDate(uint memId, uint year, uint month, uint day) external;
	function modifyMemoryName(uint memId, string memory name) external;
	function deleteMemory(uint memId) external;
}

interface P_D {
	function getByEffieIds() external view returns(uint[] memory);
    function getByKyrinIds() external view returns(uint[] memory);
    function getByEffieLockedIds() external view returns(uint[] memory);
    function getByKyrinLockedIds() external view returns(uint[] memory);
	function getDiaryById(uint diaryId) external view returns(string memory);
	function getCommentById(uint commentId) external view returns(string memory);
	function encodeDiary(string memory text, string memory secret) external pure returns (bytes memory);
	function viewLockedDiary(uint diaryId, string memory secret) external view returns (string memory);

	function addDiary(string memory text, address sender) external;
	function modifyDiaryDate(uint diaryId, uint year, uint month, uint day, address sender) external;
	function modifyDiaryText(uint diaryId, string memory text, address sender) external;
	function deleteDiary(uint diaryId, address sender) external;
	function commentDiary(uint diaryId, string memory text, address sender) external;
	function deleteComment(uint diaryId, uint commentId, address sender) external;
	function tipDiary(uint diaryId, address sender) external;
	function addLockedDiary(bytes memory e, address sender) external;
	function unlockDiary(uint diaryId, string memory secret, address sender) external;
}

interface P_C {
	function getTodoIds() external view returns(uint[] memory);
	function getDoneIds() external view returns(uint[] memory);
	function getById(uint id) external view returns(string memory);

	function addTodo(string memory name) external;
	function modifyTodo(uint id, string memory name) external;
	function deleteTodo(uint id) external;
	function finishTodo(uint id) external;
}

contract PiggyVerse{
	address public owner;
	address public pendingOwner;
	address public effie;
	address public kyrin;

	P_A public PiggyAwards;
	P_T public PiggyTasks;
	P_M public PiggyMemories;
	P_D public PiggyDiaries;
	P_C public PiggyChecklist;

	event OwnershipTransferred(address owner, address pendingOwner);
    event EffieChanged(address newEffie);
    event KyrinChanged(address newKyrin);

    /* ------------------------ Management ------------------------ */

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }
    modifier onlyPendingOwner{
        require(pendingOwner == msg.sender);
        _;
    }
    modifier onlyEffie{
    	require(effie == msg.sender);
    	_;
    }
    modifier onlyKyrin{
    	require(kyrin == msg.sender);
    	_;
    }
    modifier onlyEffieKyrin{
    	require(effie == msg.sender || kyrin == msg.sender);
    	_;
    }

    function PiggyVerse_transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }
    function PiggyVerse_claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
    function PiggyVerse_setEffie(address newEffie) public onlyOwner {
    	effie = newEffie;
    	emit EffieChanged(newEffie);
    }
    function PiggyVerse_setKyrin(address newKyrin) public onlyOwner {
    	kyrin = newKyrin;
    	emit KyrinChanged(newKyrin);
    }
    function PiggyVerse_setPiggyAwards(address p_a) public onlyOwner {
    	PiggyAwards = P_A(p_a);
    }
    function PiggyVerse_setPiggyTasks(address p_t) public onlyOwner {
    	PiggyTasks = P_T(p_t);
    }
    function PiggyVerse_setPiggyMemories(address p_m) public onlyOwner {
    	PiggyMemories = P_M(p_m);
    }
    function PiggyVerse_setPiggyDiaries(address p_d) public onlyOwner {
    	PiggyDiaries = P_D(p_d);
    }
    function PiggyVerse_setPiggyChecklist(address p_c) public onlyOwner {
    	PiggyChecklist = P_C(p_c);
    }

    /* ------------------------ PiggyAwards ------------------------ */

    function PiggyAwards_getToEffieOnSaleIds() public view returns(uint[] memory){
    	return PiggyAwards.getToEffieOnSaleIds();
    }
	function PiggyAwards_getToKyrinOnSaleIds() public view returns(uint[] memory){
		return PiggyAwards.getToKyrinOnSaleIds();
	}
	function PiggyAwards_getToEffieSaledIds() public view returns(uint[] memory){
		return PiggyAwards.getToEffieSaledIds();
	}
	function PiggyAwards_getToKyrinSaledIds() public view returns(uint[] memory){
		return PiggyAwards.getToKyrinSaledIds();
	}
	function PiggyAwards_getToEffieCanceledIds() public view returns(uint[] memory){
		return PiggyAwards.getToEffieCanceledIds();
	}
    function PiggyAwards_getToKyrinCanceledIds() public view returns(uint[] memory){
    	return PiggyAwards.getToKyrinCanceledIds();
    }
	function PiggyAwards_getSaleById(uint saleId) public view returns(string memory){
		return PiggyAwards.getSaleById(saleId);
	}

	function PiggyAwards_getToEffieIds() public view returns(uint[] memory){
		return PiggyAwards.getToEffieIds();
	}
	function PiggyAwards_getToKyrinIds() public view returns(uint[] memory){
		return PiggyAwards.getToKyrinIds();
	}
	function PiggyAwards_getToEffieDoneIds() public view returns(uint[] memory){
		return PiggyAwards.getToEffieDoneIds();
	}
	function PiggyAwards_getToKyrinDoneIds() public view returns(uint[] memory){
		return PiggyAwards.getToKyrinDoneIds();
	}
	function PiggyAwards_getAwardById(uint awardId) public view returns(string memory){
		return PiggyAwards.getAwardById(awardId);
	}

    function PiggyAwards_addOnSale(string memory name, uint cnt, uint value, bool longTerm) public {
    	return PiggyAwards.addOnSale(name, cnt, value, longTerm, msg.sender);
    }
	function PiggyAwards_deleteOnSale(uint saleId) public {
		return PiggyAwards.deleteOnSale(saleId, msg.sender);
	}
	function PiggyAwards_cancelOnSale(uint saleId) public {
		return PiggyAwards.cancelOnSale(saleId, msg.sender);
	}
	function PiggyAwards_changeOnSaleLongTerm(uint saleId) public {
		return PiggyAwards.changeOnSaleLongTerm(saleId, msg.sender);
	}
	function PiggyAwards_buyOnSale(uint saleId) public {
		return PiggyAwards.buyOnSale(saleId, msg.sender);
	}
	function PiggyAwards_addAward(string memory name, uint cnt) public {
		return PiggyAwards.addAward(name, cnt, msg.sender);
	}
	function PiggyAwards_finishAward(uint awardId) public {
		return PiggyAwards.finishAward(awardId, msg.sender);
	}
	function PiggyAwards_changeAwardCnt(uint awardId, uint cnt) public {
		return PiggyAwards.changeAwardCnt(awardId, cnt, msg.sender);
	}

	/* ------------------------ PiggyTasks ------------------------ */

	function PiggyTasks_getToEffieIds() public view returns(uint[] memory){
		return PiggyTasks.getToEffieIds();
	}
	function PiggyTasks_getToKyrinIds() public view returns(uint[] memory){
		return PiggyTasks.getToKyrinIds();
	}
	function PiggyTasks_getToEffieFinishedIds() public view returns(uint[] memory){
		return PiggyTasks.getToEffieFinishedIds();
	}
	function PiggyTasks_getToKyrinFinishedIds() public view returns(uint[] memory){
		return PiggyTasks.getToKyrinFinishedIds();
	}
	function PiggyTasks_getToEffieVerifiedIds() public view returns(uint[] memory){
		return PiggyTasks.getToEffieVerifiedIds();
	}
	function PiggyTasks_getToKyrinVerifiedIds() public view returns(uint[] memory){
		return PiggyTasks.getToKyrinVerifiedIds();
	}
	function PiggyTasks_getToEffieCanceledIds() public view returns(uint[] memory){
        return PiggyTasks.getToEffieCanceledIds();
    }
    function PiggyTasks_getToKyrinCanceledIds() public view returns(uint[] memory){
        return PiggyTasks.getToKyrinCanceledIds();
    }
	function PiggyTasks_getTaskById(uint taskId) public view returns(string memory){
		return PiggyTasks.getTaskById(taskId);
	}

	function PiggyTasks_addTask(string memory name, uint value, bool longTerm) public {
		return PiggyTasks.addTask(name, value, longTerm, msg.sender);
	}
	function PiggyTasks_deleteTask(uint taskId) public {
		return PiggyTasks.deleteTask(taskId, msg.sender);
	}
	function PiggyTasks_cancelTask(uint taskId) public {
		return PiggyTasks.cancelTask(taskId, msg.sender);
	}
	function PiggyTasks_changeTaskLongTerm(uint taskId) public {
		return PiggyTasks.changeTaskLongTerm(taskId, msg.sender);
	}
	function PiggyTasks_finishTask(uint taskId) public {
		return PiggyTasks.finishTask(taskId, msg.sender);
	}
	function PiggyTasks_verifyTask(uint taskId, bool fail) public {
		return PiggyTasks.verifyTask(taskId, fail, msg.sender);
	}

	function PiggyTasks_checkin() public {
		return PiggyTasks.checkin(msg.sender);
	}

	/* ------------------------ PiggyMemories ------------------------ */

	function PiggyMemories_getCurrentTime() public view returns(string memory){
		return PiggyMemories.getCurrentTime();
	}
	function PiggyMemories_getMemIds() public view returns(uint[] memory){
        return PiggyMemories.getMemIds();
    }
    function PiggyMemories_getMemoryById(uint memId) public view returns(string memory){
    	return PiggyMemories.getMemoryById(memId);
    }
    function PiggyMemories_getSumDaysByMemId(uint memId) public view returns(uint){
    	return PiggyMemories.getSumDaysByMemId(memId);
    }
    function PiggyMemories_getWaitDaysByMemId(uint memId) public view returns(uint){
    	return PiggyMemories.getWaitDaysByMemId(memId);
    }
    function PiggyMemories_getDateByMemIdAndSumDays(uint memId, uint sumDays) public view returns(string memory){
    	return PiggyMemories.getDateByMemIdAndSumDays(memId, sumDays);
    }

	function PiggyMemories_addMemory(uint year, uint month, uint day, string memory name) public onlyEffieKyrin {
		PiggyMemories.addMemory(year, month, day, name);
	}
	function PiggyMemories_modifyMemoryDate(uint memId, uint year, uint month, uint day) public onlyEffieKyrin {
		PiggyMemories.modifyMemoryDate(memId, year, month, day);
	}
	function PiggyMemories_modifyMemoryName(uint memId, string memory name) public onlyEffieKyrin {
		PiggyMemories.modifyMemoryName(memId, name);
	}
	function PiggyMemories_deleteMemory(uint memId) public onlyEffieKyrin {
		PiggyMemories.deleteMemory(memId);
	}

	/* ------------------------ PiggyDiaries ------------------------ */

	function PiggyDiaries_getByEffieIds() public view returns(uint[] memory){
		return PiggyDiaries.getByEffieIds();
	}
    function PiggyDiaries_getByKyrinIds() public view returns(uint[] memory){
    	return PiggyDiaries.getByKyrinIds();
    }
    function PiggyDiaries_getByEffieLockedIds() public view returns(uint[] memory){
    	return PiggyDiaries.getByEffieLockedIds();
    }
    function PiggyDiaries_getByKyrinLockedIds() public view returns(uint[] memory){
    	return PiggyDiaries.getByKyrinLockedIds();
    }
	function PiggyDiaries_getDiaryById(uint diaryId) public view returns(string memory){
		return PiggyDiaries.getDiaryById(diaryId);
	}
	function PiggyDiaries_getCommentById(uint commentId) public view returns(string memory){
		return PiggyDiaries.getCommentById(commentId);
	}
	function PiggyDiaries_encodeDiary(string memory text, string memory secret) public view returns (bytes memory){
		return PiggyDiaries.encodeDiary(text, secret);
	}
	function PiggyDiaries_viewLockedDiary(uint diaryId, string memory secret) public view returns (string memory){
		return PiggyDiaries.viewLockedDiary(diaryId, secret);
	}

	function PiggyDiaries_addDiary(string memory text) public {
		PiggyDiaries.addDiary(text, msg.sender);
	}
	function PiggyDiaries_modifyDiaryDate(uint diaryId, uint year, uint month, uint day) public {
		PiggyDiaries.modifyDiaryDate(diaryId, year, month, day, msg.sender);
	}
	function PiggyDiaries_modifyDiaryText(uint diaryId, string memory text) public {
		PiggyDiaries.modifyDiaryText(diaryId, text, msg.sender);
	}
    function PiggyDiaries_deleteDiary(uint diaryId) public {
    	PiggyDiaries.deleteDiary(diaryId, msg.sender);
    }
    function PiggyDiaries_commentDiary(uint diaryId, string memory text) public {
    	PiggyDiaries.commentDiary(diaryId, text, msg.sender);
    }
    function PiggyDiaries_deleteComment(uint diaryId, uint commentId) public {
    	PiggyDiaries.deleteComment(diaryId, commentId, msg.sender);
    }
    function PiggyDiaries_tipDiary(uint diaryId) public {
    	PiggyDiaries.tipDiary(diaryId, msg.sender);
    }
	function PiggyDiaries_addLockedDiary(bytes memory e) public {
		PiggyDiaries.addLockedDiary(e, msg.sender);
	}
	function PiggyDiaries_unlockDiary(uint diaryId, string memory secret) public {
		PiggyDiaries.unlockDiary(diaryId, secret, msg.sender);
	}

    /* ------------------------ PiggyChecklist ------------------------ */
	
    function PiggyChecklist_getTodoIds() public view returns(uint[] memory){
    	return PiggyChecklist.getTodoIds();
    }
    function PiggyChecklist_getDoneIds() public view returns(uint[] memory){
    	return PiggyChecklist.getDoneIds();
    }
    function PiggyChecklist_getById(uint id) public view returns(string memory){
    	return PiggyChecklist.getById(id);
    }

    function PiggyChecklist_addTodo(string memory name) public onlyEffieKyrin {
    	return PiggyChecklist.addTodo(name);
    }
    function PiggyChecklist_modifyTodo(uint id, string memory name) public onlyEffieKyrin {
    	return PiggyChecklist.modifyTodo(id, name);
    }
    function PiggyChecklist_deleteTodo(uint id) public onlyEffieKyrin {
    	return PiggyChecklist.deleteTodo(id);
    }
    function PiggyChecklist_finishTodo(uint id) public onlyEffieKyrin {
    	return PiggyChecklist.finishTodo(id);
    }
}