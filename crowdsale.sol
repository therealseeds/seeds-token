pragma solidity ^0.4.16;

contract token {
  function transfer(address receiver, uint amount) {}
  function mintToken(address target, uint mintedAmount) {}
}

contract Crowdsale {

  enum State {
    Fundraising, // Initial state
    Failed, // Failed reaching the minimum target
    Successful, // Completed but not transfered the fund to the funders
    Closed // All completed
  }

  State public state = State.Fundraising;

  struct Contribution {
    uint amount;
    address contributor;
  }

  Contribution[] contributions;

  uint public totalRaised;
  uint public currentBalance;
  uint public deadline; // timestamp
  uint public completed; // timestamp - when did the funding complete?
  uint public priceInWei; // Price of the token in WEI (smallest unit of Eth) 1 ETH = 1000000000000000000 WEI (18 zeros)
  uint public fundingMinimumTargetInWei;
  uint public fundingMaximumTargetInWei;
  address public creator;
  address public beneficiary; // Can be a DAO or creator
  string public campaignUrl;
  byte constant version = 1;

  token public tokenReward; // Address that holds the smart contract of the token

  event LogFundingReceived(address addr, uint amount, uint currentTotal);
  event LogBeneficiaryPaid(address beneficiary);
  event LogFundingSuccessful(uint totalRaised);
  event LogFunderInitialized(address creator, address beneficiary, string url, uint _fundingMaximumTargetInEther, uint deadline);

  function Crowdsale(
    uint _timeInMinutesForFundraising,
    string _campaignUrl,
    address _ifSuccessfulSendTo, // Beneficiary
    uint _fundingMaximumTargetInEther,
    uint _fundingMinimumTargetInEther,
    token _addressOfToken, // Token used as a reward
    uint _etherCostOfEachToken
  ) {

    creator = msg.sender;
    beneficiary = _ifSuccessfulSendTo;
    campaignUrl = _campaignUrl;
    fundingMaximumTargetInWei = _fundingMaximumTargetInEther * 1 ether;
    fundingMinimumTargetInWei = _fundingMinimumTargetInEther * 1 ether;
    deadline = now + (_timeInMinutesForFundraising * 1 Minutes);
    currentBalance = 0;
    tokenReward = token(_addressOfToken);
    priceInWei = _etherCostOfEachToken * 1 ether;

    LogFunderInitialized(creator, beneficiary, campaignUrl, fundingMinimumTargetInWei, deadline);
  }
}
