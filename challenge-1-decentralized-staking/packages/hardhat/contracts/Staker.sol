// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  enum Status{
    stake,
    success,
    withdraw
  }

  event Stake(address, uint256);

  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;
  Status public status;
  uint256 public deadline = block.timestamp + 30 hours;
  bool public isExecuted;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(
          exampleExternalContractAddress
      );
      
  }

  function stake() public payable {
      require(status == Status.stake,"Can not stake in this phase!");
      require(block.timestamp <=deadline, 'Deadline is over!');
      balances[msg.sender] += msg.value;
      emit Stake(msg.sender, msg.value);
  }

  function execute() public notCompleted{
    require(!isExecuted,"Cannot be executed! Already executed by someone else");
    require(block.timestamp>=deadline,"Deadline not yet");
    if (address(this).balance < threshold){
      status = Status.withdraw;
      console.log("Withdraw phase");
    }else{
      complete();
      console.log("Success Status!");
    }
    isExecuted = true;
  }
  function complete() private{
    status = Status.success;
    exampleExternalContract.complete{value:address(this).balance}();
  }
  function timeLeft() public view returns (uint256){
    if (block.timestamp >deadline){
      return 0;
    }
    return deadline - block.timestamp;
  }
  function withdraw() public notCompleted{
    require(status == Status.withdraw,"Cannot with draw! ");
    uint256 amount = balances[msg.sender];
    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "Failed to send Ether");
    balances[msg.sender] = 0;
  }

  function receive() external payable{
    stake();
  }

  modifier notCompleted() {
        bool completed = exampleExternalContract.completed();

        require(!completed, "The Staking process is completed");
        _;
    }


}
