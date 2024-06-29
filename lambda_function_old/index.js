const AWS = require('aws-sdk');
const Sharp = require('sharp');

const s3 = new AWS.S3();

exports.handler = async (event) => {
  const { imageKey } = JSON.parse(event.body);
  const bucket = process.env.BUCKET;

  try {
    const image = await s3.getObject({ Bucket: bucket, Key: imageKey }).promise();

    const resizedImage = await Sharp(image.Body)
      .resize(100, 100) // Resize to 100x100 pixels
      .toBuffer();

    const resizedImageKey = `resized-${imageKey}`;
    await s3.putObject({
      Bucket: bucket,
      Key: resizedImageKey,
      Body: resizedImage,
      ContentType: 'image/jpeg'
    }).promise();

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Image resized successfully', resizedImageKey }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error resizing image', error: error.message }),
    };
  }
};
