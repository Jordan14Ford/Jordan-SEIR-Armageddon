# Authenticity Checklist

What's been fixed vs what you still need to add your personal touch to.

---

## DONE (Headers Removed, Comments Simplified)

These files have been toned down. Review them and add your own notes:

### Tokyo
- [x] `tokyo/variables.tf` - simplified, descriptions shortened
- [x] `tokyo/main.tf` - headers removed, brief comments
- [x] `tokyo/sg.tf` - cleaned up, cycle error note kept
- [x] `tokyo/rds.tf` - simplified, has commented-out multi_az
- [x] `tokyo/ec2_app.tf` - cleaned, has TODO notes
- [x] `tokyo/tgw.tf` - simplified
- [x] `tokyo/routes.tf` - minimal now

### Sao Paulo
- [x] `sao-paulo/main.tf` - simplified, "copied from tokyo" note
- [x] `sao-paulo/ec2_app.tf` - cleaned up
- [x] `sao-paulo/tgw.tf` - simplified

### Notes
- [x] `notes/decisions_review.md` - DELETED (was too polished)

---

## YOUR TURN - Add Personal Notes

Go through these files and add YOUR voice. Examples to scatter around:

```hcl
# finally got this working
# not sure if this is right but it works
# from AWS docs
# TODO: ask about this
# tried X first, didn't work
# copied from lab 2
# this kept breaking until i added the depends_on
```

### Files to personalize:

1. **tokyo/variables.tf** - Add a note about where you got the AMI ID
2. **tokyo/main.tf** - Add a struggle note about NAT gateway or subnets
3. **tokyo/rds.tf** - Add something about encryption or backup settings
4. **tokyo/sg.tf** - Mention why you split the rules (already has note)
5. **tokyo/ec2_app.tf** - Add Flask debugging notes
6. **sao-paulo/main.tf** - Already has "copied from tokyo" note
7. **sao-paulo/ec2_app.tf** - Add note about TGW connection to tokyo

---

## STILL NEED SIMPLIFYING

Check these and simplify if they still look too polished:

- [ ] `sao-paulo/variables.tf` - shorten descriptions
- [ ] `sao-paulo/sg.tf` - remove verbose comments if any
- [ ] `sao-paulo/routes.tf` - simplify if needed
- [ ] `tokyo/outputs.tf` - check if too verbose
- [ ] `sao-paulo/outputs.tf` - check if too verbose

---

## Files That Are Fine As-Is

- `notes/lab3_todo.md` - looks like a real checklist
- `notes/lab3_status.md` - short and simple
- `notes/lab3_scope.md` - brief notes
- `notes/deleted_nat_gateways.md` - reference doc, fine

---

## Quick Authenticity Adds

If short on time, just add these 5 things:

1. One "# finally got this working" somewhere
2. One "# from AWS docs: [url]" reference
3. One commented-out failed attempt
4. One "# TODO: figure out X" 
5. One "# copied from lab 2" in sao paulo
