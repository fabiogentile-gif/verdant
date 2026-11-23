const app = require("./app");
const config = require("./config");
const { startWorker } = require("./services/reminders");

app.listen(config.port, () => {
  console.log(`Server is running on port ${config.port}`);
  startWorker();
});
