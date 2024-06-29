exports.handler = async (event) => {
    const currentDate = new Date();
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Current date and time',
        date: currentDate.toString()
      }),
    };
  };
  