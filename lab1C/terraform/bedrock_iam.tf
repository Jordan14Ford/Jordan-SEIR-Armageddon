resource "aws_iam_role_policy_attachment" "bedrock_policy" {
  role       = aws_iam_role.lab1c_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}