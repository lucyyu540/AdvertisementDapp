App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  hasVoted: false,

  init: function() {
    return App.initWeb3();
  },
  //connects client-side to local blockchain 
  initWeb3: function() {
    // TODO: refactor conditional
    //instance of web3 attached to the window from meta mask
    //meta mask is the extension that turns chrome browser into a blockchain browser, which can connect 
    //to the ethereum network 
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  //loads up contract into front end app so that we i can interact with it
  initContract: function() {
    $.getJSON("DAO.json", function(dao) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.DAO = TruffleContract(dao);
      // Connect provider to interact with contract
      App.contracts.DAO.setProvider(App.web3Provider);

      App.listenForEvents();

      return App.render();
    });
  },

  // Listen for events emitted from the contract
  listenForEvents: function() {
    App.contracts.DAO.deployed().then(function(instance) {
      // Restart Chrome if you are unable to receive this event
      // This is a known issue with Metamask
      // https://github.com/MetaMask/metamask-extension/issues/2393
      instance.lotteryWin({}, {
        fromBlock: 0,
        toBlock: 'latest'
      }).watch(function(error, event) {
        console.log("event triggered", event)
        // Reload when a new vote is recorded
        App.render();
      });
    });
  },


  //lays out content of the page
  render: function() {
    var daoInstance;
    var loader = $("#loader");
    var content = $("#content");

    loader.show();
    content.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      }
    });



    // Load contract data
    App.contracts.DAO.deployed().then(function(instance) {
      daoInstance = instance;
      return daoInstance.numOfLotteryContracts();
    }).then(function(lotteryCount) {
      var lotteryResults = $("#lotteryResults");
      lotteryResults.empty();

      //add all lotteries to the table 
      for (var i = 1; i <= lotteryCount; i++) {
        daoInstance.deployedLotteryContracts(i).then(function(lotteryStruct) {
          var lotteryContractAddress = lotteryStruct[0];
          var owner = lotteryStruct[1];
          var winner = lotteryStruct[2];

          // Render candidate Result
          var lotteryTemplate = "<tr><th>" + lotteryContractAddress + "</th><td>" + owner  + "</td><td>"  + winner + "</td></tr>"
          lotteryResults.append(lotteryTemplate);

        });
      }
      loader.hide();
      content.show();
    }).catch(function(error) {
      console.warn(error);
    });
  },

  //these functions are going to be applied as onSubmit handler in index.html
  runLotteryForFirstTime: function() {
    var ticketsPerCycle = $('#ticketsPerCycle').val();
    var pool = $('#pool').val();
    var entrances = $('#entrances').val();

    App.contracts.DAO.deployed().then(function(instance) {
      return instance.runLoterryForFirstTime(ticketsPerCycle, pool, entrances, { from: App.account });
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });
  }

  runLottery: function() {
    var lotteryContractAddress = $('#lotteryContractAddress').val();
    var ticketsPerCycle = $('#ticketsPerCycle').val();
    var pool = $('#pool').val();
    var entrances = $('#entrances').val();

    App.contracts.DAO.deployed().then(function(instance) {
      return instance.runLoterry(lotteryContractAddress, ticketsPerCycle, pool, entrances, { from: App.account });
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });
  }
  //if validated 
  sendTokensToWinner: function() {
    var lotteryContractAddress = $('#lotteryContractAddress').val();

    App.contracts.DAO.deployed().then(function(instance) {
      return instance.sendTokensToWinner(lotteryContractAddress, { from: App.account });
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });
  }

};
//initialize the app whenever the window loads
$(function() {
  $(window).load(function() {
    App.init();
  });
});